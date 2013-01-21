class HaDope
  class GPU
    include HadopeBackend

    @@singleton = nil

    def initialize
      puts "Init Time: #{Benchmark.realtime{ init_OpenCL_environment }}"
    end

    def load(dataset_name)
      dataset = HaDope::DataSet[dataset_name]
      puts "Buffer Time: #{Benchmark.realtime{ @membuffer = create_memory_buffer(dataset.data[:size], dataset.required_memory) }}"
      puts "Dataset Input Time: #{Benchmark.realtime{ load_int_dataset(dataset.data[:values], @membuffer) }}"
      self
    end

    def map(task_name)
      map_task = HaDope::Map[task_name]
      kernel = map_task.kernel
      puts "#{task_name} Time: #{Benchmark.realtime{ run_task(kernel, kernel.length, map_task.name.to_s, @membuffer) }}"
      self
    end

    def filter(task_name)
      self
    end

    def output
      dataset = []
      puts "Dataset Output Time: #{Benchmark.realtime{ dataset = retrieve_int_dataset(@membuffer) }}"
      dataset
    end

    def clean
      clean_used_resources(@membuffer)
    end

    def self.get
      @@singleton ||= self.new
    end

  end
end
