class HaDope
  class CPU
    include HadopeBackend
    include DeviceMethods

    @@singleton = nil

    def initialize
      puts "Init Time: #{Benchmark.realtime{ @environment = init_CPU_environment }}"
    end

    def self.get
      @@singleton ||= self.new
    end

  end
end
