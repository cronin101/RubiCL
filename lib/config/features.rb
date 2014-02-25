module Hadope
  module Config

    class FeatureSwitcher
      attr_accessor :task_fusion

      def initialize
        set_defaults
      end

      private

      def set_defaults
        @task_fusion = true
      end

    end

    Features =  FeatureSwitcher.new
  end
end
