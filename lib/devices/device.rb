module Hadope
  class Device
    include HadopeBackend
    include RequireType
    include ChainableDecorator

    def is_hybrid?
      false
    end

    class << self
      attr_accessor :singleton

      def get
        @singleton ||= new
      end
    end

    FIX2INT = [:int, :x, ['x = x >> 1']]
    INT2FIX = [:int, :x, ['x = (x << 1) | 0x01']]


    Cache = Struct.new(:dataset)

    def initialize
      raise 'Must be a subclass!' if self.class == Device
      initialize_task_queue
      @logger = Logger.get
      @cache = Cache.new(nil)
    end

    def [](type)
      send type.hadope_conversion
    end

    def load_integer_object obj
      case obj
      when Array
        load_integer_dataset obj
      when File
        pin_integer_file obj
      when Range
        load_integer_dataset obj.to_a
      else
        raise "No idea how to pin #{obj.inspect}!"
      end
    end

    def load_integer_dataset d
      if Hadope::Config::Features.use_host_mem
        pin_integer_dataset d
      else
        create_integer_buffer_from_dataset d
      end
    end

    chainable sets_type :int,
    def create_integer_buffer_from_dataset(array)
      @buffer = create_memory_buffer array.length, 'int'
      transfer_integer_dataset_to_buffer array, @buffer
    end

    chainable sets_type :int,
    def pin_integer_dataset(array)
      @buffer = create_buffer_from_dataset :pinned_integer_buffer, array
    end

    chainable sets_type :int,
    def pin_integer_file file
      @buffer = create_buffer_from_dataset :pinned_intfile_buffer, file.path
      @cache.dataset = nil
    end

    chainable sets_type :double,
    def pin_double_dataset(array)
      @buffer = create_buffer_from_dataset :pinned_double_buffer, array
    end
    alias_method :load_double_dataset, :pin_double_dataset

    def sort
      @cache.dataset = nil
      case loaded_type
      when :int then run_sort_int_buffer_task
      else
        raise "Not sure how to sort the type: #{loaded_type.inspect}"
      end
    end

    chainable requires_type :int,
    def run_sort_int_buffer_task
      sort_integer_buffer Sort.new(type: :int).to_kernel, @buffer
    end

    chainable requires_type :int, (sets_type :int_tuple,
    def zip(array)
      # FIXME: Expose buffer length
      #raise "Second dataset must be the same length as the first." unless @buffer.length == array.length
      @fsts = @buffer
      @snds = create_buffer_from_dataset :pinned_integer_buffer, array.to_a

      @cache.dataset = nil
      @task_queue.push SMap.new(*FIX2INT)
    end)

    chainable requires_type :int_tuple, (sets_type :int,
    def braid(&block)
      raise "Braid function has incorrect arity." unless block.arity == 2
      expression = LambdaBytecodeParser.new(block).to_infix.first
      @task_queue.push Braid.new(:int, :x, :y, expression)
    end)

    chainable def map(&block)
      @cache.dataset = nil
      expression = LambdaBytecodeParser.new(block).to_infix.first
      if unary_types.include? loaded_type
        @task_queue.push Map.new(loaded_type, :x, ["x = #{expression}"])
      else
        raise "#map not implemented for #{loaded_type.inspect}"
      end
    end

    chainable def filter(&block)
      @cache.dataset = nil
      predicate = LambdaBytecodeParser.new(block).to_infix.first
      if unary_types.include? loaded_type
        @task_queue.push Filter.new(loaded_type, :x, predicate)
      else
        raise "#filter not implemented for #{loaded_type.inspect}"
      end
    end

    alias_method :collect, :map
    alias_method :select, :filter

    chainable def scan(style=:inclusive, operator)
      @cache.dataset = nil
      if unary_types.include? loaded_type
        @task_queue.push Scan.new(style:style, type:loaded_type, operator:operator, elim_conflicts: self.is_a?(GPU))
      else
        raise "#scan not implemented for #{loaded_type.inspect}"
      end
    end

    def retrieve_integer_dataset
      if Hadope::Config::Features.use_host_mem
        retrieve_pinned_integer_dataset
      else
        retrieve_integer_dataset
      end
    end

    requires_type :int,
    def retrieve_pinned_integer_dataset
      retrieve_from_device :pinned_integer_dataset
    end

    requires_type :int,
    def retrieve_integer_dataset
      retrieve_from_device :integer_dataset
    end

    requires_type :double,
    def retrieve_pinned_double_dataset
      retrieve_from_device :pinned_double_dataset
    end

    requires_type :int,
    def sum
      @task_queue.unshift Map.new(*FIX2INT)
      run_tasks(do_conversions:false)
      scan_kernel = Scan.new(type: :int, operator: :+, elim_conflicts: self.is_a?(GPU)).to_kernel
      sum_integer_buffer scan_kernel, @buffer
    end

    def count(needle)
      @task_queue.unshift Map.new(*FIX2INT) if loaded_type == :int
      run_tasks(do_conversions:false)
      if unary_types.include? loaded_type
        task = Filter.new(loaded_type, :x, "x == #{needle}")
        kernel = task.to_kernel
        scan_kernel = Scan.new(type: :int, operator: :+, elim_conflicts: self.is_a?(GPU)).to_kernel
        count_post_filter(kernel, task.name, scan_kernel, @buffer)
      else
        raise "#count not implemented for #{loaded_type.inspect}"
      end
    end

    private

    def initialize_task_queue
      @task_queue = TaskQueue.new
    end

    def run_map(task)
      kernel = task.to_kernel
      @logger.log "Executing map kernel:\n #{kernel}"
      run_map_task(kernel, task.name, @buffer)
    end

    def run_smap(task)
      kernel = task.to_kernel
      @logger.log "Executing smap kernel:\n #{kernel}"
      run_map_task(kernel, task.name, @snds)
    end

    def run_filter(task)
      kernel = task.to_kernel
      @logger.log "Executing filter kernel:\n #{kernel}"
      scan_kernel = Scan.new(type: :int, operator: :+, elim_conflicts: self.is_a?(GPU)).to_kernel
      run_filter_task(kernel, task.name, scan_kernel, @buffer)
    end

    def run_braid(task)
      kernel = task.to_kernel
      @logger.log "Executing braid kernel:\n #{kernel}"
      @buffer = run_braid_task(kernel, task.name, @fsts, @snds)
    end

    def run_scan(task)
      scan_kernel = task.to_kernel
      @logger.log "Executing scan kernel:\n #{scan_kernel}"
      case task.style
      when :exclusive
        run_exclusive_scan_task(scan_kernel, @buffer)
      when :inclusive
        braid_task = Braid.new(loaded_type, :x, :y, 'x + y')
        @logger.log "Executing braid kernel:\n #{braid_task.to_kernel}"
        run_inclusive_scan_task(scan_kernel, braid_task.to_kernel, braid_task.name, @buffer)
      else
        raise "Don't understand scan type: #{task.style}"
      end
    end

    def run_task(task)
      case task
      when SMap   then run_smap   task
      when Map    then run_map    task
      when Filter then run_filter task
      when Braid  then run_braid  task
      when Scan   then run_scan   task
      else raise "Unknown task: #{task.inspect}"
      end
    end

    def run_tasks(do_conversions:(loaded_type == :int))
      if do_conversions
        @task_queue.unshift Map.new(*FIX2INT)
        @task_queue.push Map.new(*INT2FIX)
      end
      @task_queue.simplify! if Hadope::Config::Features.task_fusion
      run_task @task_queue.shift until @task_queue.empty?
    end

    def create_buffer_from_dataset(buffer_type, dataset)
      @task_queue.clear
      send("create_#{buffer_type}", @cache.dataset = dataset)
    end

    def retrieve_from_device dataset_type
      if @cache.dataset
        @cache.dataset
      else
        run_tasks unless @task_queue.empty?
        @cache.dataset = send("retrieve_#{dataset_type}_from_buffer", @buffer)
      end
    end

  end
end
