class HaDope
  class GPU
    include HadopeBackend
    include DeviceMethods

    @@singleton = nil

    def initialize
      puts "Init Time: #{Benchmark.realtime{ @environment = init_GPU_environment }}"
    end

    def self.get
      @@singleton ||= self.new
    end

  end
end
