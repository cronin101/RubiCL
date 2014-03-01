module Hadope
  class Device
    require 'colored'

    include HadopeDeviceBackend
    include HadopeTaskBackend

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

    # Decorators for start/during/end of computation callbacks
    def self.pipeline_start method
      method_body = instance_method method
      define_method method do |*arg, &block|
        Logger.timing_info "Pipeline Started".red
        method_body.bind(self).(*arg, &block)
      end
    end

    def self.cache_invalidator method
      method_body = instance_method method
      define_method method do |*arg, &block|
        @buffer.invalidate_cache
        method_body.bind(self).(*arg, &block)
      end
    end

    def self.pipeline_stop method
      method_body = instance_method method
      define_method method do |*arg, &block|
        run_tasks
        result = method_body.bind(self).(*arg, &block)
        Logger.timing_info "Pipeline Complete".green + " in #{last_pipeline_duration.round(3).to_s.green} ms"
        result
      end
    end

    def initialize
      raise 'Must be a subclass!' if self.class == Device
      initialize_task_queue
      @buffer = Hadope::DeviceService::BufferManager.new(@environment)
    end

    def [](type)
      send type.hadope_conversion
    end

    chainable pipeline_start def load_object(type, object)
      @buffer.load(type: type, object: object)
    end

    chainable cache_invalidator def sort
      type = @buffer.type
      task = Sort.new(type: type)
      case type
      when :int then sort_integer_buffer task.to_kernel, @buffer.access(type: :int)
      else
        raise "Not sure how to sort the type: #{loaded_type.inspect}"
      end
    end

    chainable cache_invalidator def zip(array)
      run_tasks
      @buffer.zip_load(snd: array)
      @task_queue.push SMap.new(*FIX2INT)
    end

    chainable cache_invalidator def fsts
      run_tasks
      @buffer.zipped_choose :fst
    end

    chainable cache_invalidator def snds
      @task_queue.push SMap.new(*INT2FIX)
      run_tasks(do_conversions: false)
      @buffer.zipped_choose :snd
    end

    chainable def braid(&block)
      raise "Braid function has incorrect arity." unless block.arity == 2
      expression = LambdaBytecodeParser.new(block).to_infix.first
      @task_queue.push Braid.new(:int, :x, :y, expression)
      @buffer.type = :int
    end

    chainable cache_invalidator def map(&block)
      expression = LambdaBytecodeParser.new(block).to_infix.first
      if @buffer.unary_type?
        @task_queue.push Map.new(@buffer.type, :x, ["x = #{expression}"])
      else
        raise "#map not implemented for non-unary types"
      end
    end

    chainable cache_invalidator def filter(&block)
      predicate = LambdaBytecodeParser.new(block).to_infix.first
      if @buffer.unary_type?
        @task_queue.push Filter.new(@buffer.type, :x, predicate)
      else
        raise "#filter not implemented for non-unary types"
      end
    end

    alias_method :collect, :map
    alias_method :select, :filter

    chainable cache_invalidator def scan(style=:inclusive, operator)
      if @buffer.unary_type?
        @task_queue.push Scan.new(
          style: style, type: @buffer.type, operator:operator, elim_conflicts: self.is_a?(GPU)
        )
      else
        raise "#scan not implemented for non-unary types"
      end
    end

    pipeline_stop def retrieve_integers
      @buffer.retrieve(type: :int)
    end

    pipeline_stop def retrieve_doubles
      @buffer.retrieve(type: :double)
    end

    def sum
      case @buffer.type
      when :int
        @task_queue.unshift Map.new(*FIX2INT)
        run_tasks(do_conversions: false)
        scan_kernel = Scan.new(type: @buffer.type, operator: :+, elim_conflicts: self.is_a?(GPU)).to_kernel
        sum_integer_buffer scan_kernel, @buffer.access(type: :int)
      else
        raise "Cannot sum currently loaded type: #{@buffer.type}"
      end
    end

    def count(needle)
      @task_queue.unshift Map.new(*FIX2INT) if @buffer.type == :int
      run_tasks(do_conversions: false)

      if @buffer.unary_type?
        task = Filter.new(@buffer.type, :x, "x == #{needle}")
        kernel = task.to_kernel
        scan_kernel = Scan.new(type: @buffer.type, operator: :+, elim_conflicts: self.is_a?(GPU)).to_kernel
        count_post_filter(kernel, task.name, scan_kernel, @buffer.access(type: @buffer.type))
      else
        raise "#count not implemented for non-unary types"
      end
    end

    private

    def initialize_task_queue
      @task_queue = TaskQueue.new
    end

    def run_map(task)
      kernel = task.to_kernel
      Logger.log "Executing map kernel:\n #{kernel}"
      run_map_task(kernel, task.name, @buffer.access(type: task.type))
    end

    def run_smap(task)
      kernel = task.to_kernel
      Logger.log "Executing smap kernel:\n #{kernel}"
      _, snd = @buffer.zip_retrieve
      run_map_task(kernel, task.name, snd)
    end

    def run_filter(task)
      type = task.type
      kernel = task.to_kernel
      Logger.log "Executing filter kernel:\n #{kernel}"
      scan_kernel = Scan.new(type: :int, operator: :+, elim_conflicts: self.is_a?(GPU)).to_kernel
      run_filter_task(kernel, task.name, scan_kernel, @buffer.access(type: type))
    end

    def run_braid(task)
      kernel = task.to_kernel
      Logger.log "Executing braid kernel:\n #{kernel}"
      run_braid_task(kernel, task.name, *@buffer.zip_retrieve)
    end

    def run_scan(task)
      scan_kernel = task.to_kernel
      type = task.type
      Logger.log "Executing scan kernel:\n #{scan_kernel}"
      case task.style
      when :exclusive
        run_exclusive_scan_task(scan_kernel, @buffer.access(type: type))
      when :inclusive
        braid_task = Braid.new(type, :x, :y, 'x + y')
        Logger.log "Executing braid kernel:\n #{braid_task.to_kernel}"
        run_inclusive_scan_task(scan_kernel, braid_task.to_kernel, braid_task.name, @buffer.access(type: type))
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

      Logger.timing_info "Enqueued #{task.descriptor.yellow} in #{last_computation_duration.round(3).to_s.green} ms"
    end

    def run_tasks(do_conversions:(@buffer.type == :int))
      if do_conversions
        @task_queue.unshift Map.new(*FIX2INT)
        @task_queue.push Map.new(*INT2FIX)
      end
      @task_queue.simplify! if Hadope::Config::Features.task_fusion
      run_task @task_queue.shift until @task_queue.empty?
    end

  end

end
