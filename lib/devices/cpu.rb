class HaDope
  class CPU
    include HadopeBackend
    include DeviceMethods

    class << self
      attr_accessor :singleton

      def get
        @singleton ||= new
      end
    end

    def initialize
      #puts "Init Time: #{Benchmark.realtime{ 
      @environment = init_CPU_environment
      #}}.inspect"
      self
    end
  end
end
