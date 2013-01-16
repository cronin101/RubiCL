class HaDope
  class GPU
    include HadopeBackend

    def load(dataset_name)
      dataset = HaDope::DataSet[dataset_name]
      init_OpenCL_environment(dataset.required_memory)
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

  end
end
