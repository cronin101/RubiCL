class Hadope::Device
  include HadopeBackend

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

  def load_integer_dataset(array)
    @task_queue.clear
    @buffer = create_memory_buffer(array.size, 'int')
    transfer_integer_dataset_to_buffer(@cache.dataset = array, @buffer)
    self
  end

  def pin_integer_dataset(array)
    @task_queue.clear
    @buffer = create_pinned_buffer(@cache.dataset = array)
    self
  end

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

  def retrieve_integer_dataset
    if @cache.dataset
      @cache.dataset
    else
      run_tasks unless @task_queue.empty?
      @cache.dataset = retrieve_integer_dataset_from_buffer @buffer
    end
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

  def run_tasks
    @task_queue.unshift Hadope::Map.new(*FIX2INT)
    @task_queue.push Hadope::Map.new(*INT2FIX)
    @task_queue.simplify!
    run_task @task_queue.shift until @task_queue.empty?
  end

end
