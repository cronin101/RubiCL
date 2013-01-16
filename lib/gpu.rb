class HaDope
  class GPU
    include HadopeBackend

    def load(dataset)
      init_OpenCL_environment
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
