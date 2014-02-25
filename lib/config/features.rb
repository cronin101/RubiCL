module Hadope
  module Config

    class FeatureSwitcher
      attr_accessor :task_fusion,
        :use_host_mem

      def initialize
        set_defaults
      end

      private

      def set_defaults
        @task_fusion  = true
        @use_host_mem = true
      end

    end

    Features =  FeatureSwitcher.new
  end
end
