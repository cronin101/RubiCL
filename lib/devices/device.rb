class Hadope::Device
  include HadopeBackend
  include Hadope::RequireType
  include Hadope::ChainableDecorator

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
    raise 'Must be a subclass!' if self.class == Hadope::Device
    initialize_task_queue
    @logger = Hadope::Logger.get
    @cache = Cache.new(nil)
  end

  def [](type)
    send type.hadope_conversion
  end

  chainable sets_type :int,
  def pin_integer_dataset(array)
    @buffer = create_buffer_from_dataset :pinned_integer_buffer, array
  end
  alias_method :load_integer_dataset, :pin_integer_dataset

  chainable sets_type :double,
  def pin_double_dataset(array)
    @buffer = create_buffer_from_dataset :pinned_double_buffer, array
  end
  alias_method :load_double_dataset, :pin_double_dataset

  chainable requires_type :int, (sets_type :int_tuple,
  def zip(array)
    raise "Second dataset must be the same length as the first." unless @buffer.length == array.length
    @cache.dataset = nil

    @fsts = @buffer
    @snds = create_pinned_buffer(array)
    @task_queue.push Hadope::SMap.new(*FIX2INT)
  end)

  chainable requires_type :int_tuple, (sets_type :int,
  def braid(&block)
    raise "Braid function has incorrect arity." unless block.arity == 2
    expression = Hadope::LambdaBytecodeParser.new(block).to_infix.first
    @task_queue.push Hadope::Braid.new(:x, :y, expression)
  end)

  chainable def map(&block)
    @cache.dataset = nil
    expression = Hadope::LambdaBytecodeParser.new(block).to_infix.first
    if unary_types.include? loaded_type
      @task_queue.push Hadope::Map.new(loaded_type, :x, ["x = #{expression}"])
    else
      raise "#map not implemented for #{loaded_type.inspect}"
    end
  end

  chainable def filter(&block)
    @cache.dataset = nil
    predicate = Hadope::LambdaBytecodeParser.new(block).to_infix.first
    if unary_types.include? loaded_type
      @task_queue.push Hadope::Filter.new(loaded_type, :x, predicate)
    else
      raise "#filter not implemented for #{loaded_type.inspect}"
    end
  end

  alias_method :collect, :map
  alias_method :select, :filter

  requires_type :int,
  def retrieve_pinned_integer_dataset
    retrieve_from_device :pinned_integer_dataset
  end

  alias_method :retrieve_integer_dataset, :retrieve_pinned_integer_dataset

  requires_type :double,
  def retrieve_pinned_double_dataset
    retrieve_from_device :pinned_double_dataset
  end

  requires_type :int,
  def sum
    @task_queue.unshift Hadope::Map.new(*FIX2INT)
    run_tasks(do_conversions:false)
    scan_kernel = Hadope::Scan.new(type: :int, operator: :+).to_kernel
    sum_integer_buffer scan_kernel, @buffer
  end

  def count(needle)
    @task_queue.unshift Hadope::Map.new(*FIX2INT) if loaded_type == :int
    run_tasks(do_conversions:false)
    if unary_types.include? loaded_type
      task = Hadope::Filter.new(loaded_type, :x, "x == #{needle}")
      kernel = task.to_kernel
      scan_kernel = Hadope::Scan.new(type: :int, operator: :+).to_kernel
      count_post_filter(kernel, task.name, scan_kernel, @buffer)
    else
      raise "#count not implemented for #{loaded_type.inspect}"
    end
  end

  private

  def initialize_task_queue
    @task_queue = Hadope::TaskQueue.new
  end

  def run_map(task)
    kernel = task.to_kernel
    @logger.log "Executing map kernel: #{kernel.inspect}"
    run_map_task(kernel, task.name, @buffer)
  end

  def run_smap(task)
    kernel = task.to_kernel
    @logger.log "Executing smap kernel: #{kernel.inspect}"
    run_map_task(kernel, task.name, @snds)
  end

  def run_filter(task)
    kernel = task.to_kernel
    @logger.log "Executing filter kernel: #{kernel.inspect}"
    scan_kernel = Hadope::Scan.new(type: :int, operator: :+).to_kernel
    run_filter_task(kernel, task.name, scan_kernel, @buffer)
  end

  def run_braid(task)
    kernel = task.to_kernel
    @logger.log "Executing braid kernel: #{kernel.inspect}"
    @buffer = run_braid_task(kernel, task.name, @fsts, @snds)
  end

  def run_task(task)
    case task
    when Hadope::SMap   then run_smap   task
    when Hadope::Map    then run_map    task
    when Hadope::Filter then run_filter task
    when Hadope::Braid  then run_braid  task
    else raise "Unknown task: #{task.inspect}"
    end
  end

  def run_tasks(do_conversions:(loaded_type == :int))
    if do_conversions
      @task_queue.unshift Hadope::Map.new(*FIX2INT)
      @task_queue.push Hadope::Map.new(*INT2FIX)
    end
    @task_queue.simplify!
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
