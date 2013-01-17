class HaDope
  class GPU
    include HadopeBackend

    @@singleton = nil

    def initialize
      puts "Init Time: " << Benchmark.realtime{ init_OpenCL_environment }.to_s
    end

    def load(dataset_name)
      dataset = HaDope::DataSet[dataset_name]
      puts "Buffer Time: " << Benchmark.realtime{ create_memory_buffer(dataset.required_memory) }.to_s
      self
    end

    def map(definition)
      self
    end

    def filter(definition)
      self
    end

    def output
      []
    end

    def self.get
      @@singleton ||= self.new
    end

  end
end
