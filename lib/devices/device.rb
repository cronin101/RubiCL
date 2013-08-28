class Hadope::Device
  include HadopeBackend

  def initialize
    raise "Must be a subclass!" if self.class == Hadope::Device
    initialize_task_queue
  end

  def [](command)
    self.send command
  end

  def load_integer_dataset(array)
    @buffer = create_memory_buffer(array.size, 'int')
    transfer_integer_dataset_to_buffer(array, @buffer)
    self
  end

  def map(opts)
    key, value = opts.first
    @task_queue.push Hadope::Map.new(key, "#{key} = #{value}")
    self
  end

  def retrieve_integer_dataset
    run_tasks
    retrieve_integer_dataset_from_buffer @buffer
  end

  private

  def initialize_task_queue
    @task_queue = Hadope::TaskQueue.new
  end

  def run_map(task)
    kernel = task.to_kernel
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
  end

end
