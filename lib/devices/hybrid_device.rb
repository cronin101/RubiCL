module Hadope

  class HybridDevice < Device
    require 'benchmark'

    BENCHMARKS = {
      map:        :map_test_benchmark,
      filter:     :filter_task_benchmark,
      mapfilter:  :mapfilter_task_benchmark,
    }

    def is_hybrid?
      true
    end

    class << self
      attr_accessor :singleton

      def get
        @singleton ||= new
      end
    end

    def initialize
      @ratio = {}
      #BENCHMARKS.each { |task, test| @ratio[task] = send test }
      @environment = initialize_hybrid_environment
      super
    end

    def [](type)
      send type.hadope_conversion
    end

  end

end
