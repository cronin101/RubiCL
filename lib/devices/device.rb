class Hadope::Device
  include HadopeBackend

  Cache = Struct.new(:dataset)

  def initialize
    raise "Must be a subclass!" if self.class == Hadope::Device
    initialize_task_queue
    @logger = Hadope::Logger.get
    @cache = Cache.new(nil)
  end

  def [](type)
    self.send type.hadope_conversion
  end

  def load_integer_dataset(array)
    @buffer = create_memory_buffer(array.size, 'int')
    transfer_integer_dataset_to_buffer(@cache.dataset = array, @buffer)
    self
  end

  def map(&block)
    expression = Hadope::LambdaBytecodeParser.new(block).to_infix.first
    @task_queue.push Hadope::Map.new(:x, "x = #{expression}")
    self
  end

  def retrieve_integer_dataset
    run_tasks unless @task_queue.empty?
    @cache.dataset ||= retrieve_integer_dataset_from_buffer @buffer
  end

  private

  def initialize_task_queue
    @task_queue = Hadope::TaskQueue.new
  end

  def run_map(task)
    kernel = task.to_kernel
    @logger.log "Executing kernel: #{kernel.inspect}"
    run_map_task(kernel, kernel.length, task.name, @buffer)
  end

  def run_task(task)
    case task
    when Hadope::Map then run_map task
    end
  end

  def run_tasks
    @task_queue.simplify!
    run_task @task_queue.shift until @task_queue.empty?
    @cache.dataset = nil
  end

end
