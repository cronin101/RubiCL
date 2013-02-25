class HaDope
  class GPU
    include HadopeBackend
    include DeviceMethods

    class << self
      attr_accessor :singleton

      def get
        @singleton ||= new
      end
    end

    def initialize
      puts "Init Time: #{Benchmark.realtime{ @environment = init_GPU_environment }}"
    end
  end
end
