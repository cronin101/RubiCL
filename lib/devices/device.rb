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

  def retrieve_integer_dataset
    retrieve_integer_dataset_from_buffer @buffer
  end

  private

  def initialize_task_queue
    @task_queue = Hadope::TaskQueue.new
  end

end
