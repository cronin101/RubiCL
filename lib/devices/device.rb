class Hadope::Device
  include HadopeBackend
  include Hadope::RequireType

  FIX2INT = [:x, 'x = x >> 1']
  INT2FIX = [:x, 'x = (x << 1) | 0x01']

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

  sets_type :int,
  def load_integer_dataset(array)
    @task_queue.clear
    @buffer = create_memory_buffer(array.size, 'int')
    transfer_integer_dataset_to_buffer(@cache.dataset = array, @buffer)
    self
  end

  sets_type :int,
  def pin_integer_dataset(array)
    @task_queue.clear
    @buffer = create_pinned_buffer(@cache.dataset = array)
    self
  end

  requires_type :int, (sets_type :int_tuple,
  def zip(array)
    @cache.dataset = nil
    @task_queue.clear

    @fsts = @buffer
    @snds = create_pinned_buffer(array)
  end)

  def map(&block)
    @cache.dataset = nil
    expression = Hadope::LambdaBytecodeParser.new(block).to_infix.first
    @task_queue.push Hadope::Map.new(:x, "x = #{expression}")
    self
  end

  def filter(&block)
    @cache.dataset = nil
    predicate = Hadope::LambdaBytecodeParser.new(block).to_infix.first
    @task_queue.push Hadope::Filter.new(:x, predicate)
    self
  end

  alias_method :collect, :map
  alias_method :select, :filter

  requires_type :int,
  def retrieve_integer_dataset
    if @cache.dataset
      @cache.dataset
    else
      run_tasks unless @task_queue.empty?
      @cache.dataset = retrieve_integer_dataset_from_buffer @buffer
    end
  end

  requires_type :int,
  def retrieve_pinned_integer_dataset
    if @cache.dataset
      @cache.dataset
    else
      run_tasks unless @task_queue.empty?
      @cache.dataset = retrieve_pinned_integer_dataset_from_buffer @buffer
    end
  end

  requires_type :int,
  def sum
    @task_queue.unshift Hadope::Map.new(*FIX2INT)
    run_tasks(do_conversions:false)
    sum_integer_buffer @buffer
  end

  requires_type :int,
  def count(needle)
    @task_queue.unshift Hadope::Map.new(*FIX2INT)
    run_tasks(do_conversions:false)
    task = Hadope::Filter.new(:x, "x == #{needle}")
    kernel = task.to_kernel
    count_post_filter(kernel, kernel.length, task.name, @buffer)
  end

  private

  def initialize_task_queue
    @task_queue = Hadope::TaskQueue.new
  end

  def run_map(task)
    kernel = task.to_kernel
    @logger.log "Executing map kernel: #{kernel.inspect}"
    run_map_task(kernel, kernel.length, task.name, @buffer)
  end

  def run_filter(task)
    kernel = task.to_kernel
    @logger.log "Executing filter kernel: #{kernel.inspect}"
    run_filter_task(kernel, kernel.length, task.name, @buffer)
  end

  def run_task(task)
    case task
    when Hadope::Map    then run_map task
    when Hadope::Filter then run_filter task
    end
  end

  def run_tasks(do_conversions:true)
    if do_conversions
      @task_queue.unshift Hadope::Map.new(*FIX2INT)
      @task_queue.push Hadope::Map.new(*INT2FIX)
    end
    @task_queue.simplify!
    run_task @task_queue.shift until @task_queue.empty?
  end

end
