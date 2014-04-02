module RubiCL
  module Config

    class FeatureSwitcher
      attr_accessor :task_fusion,
        :use_host_mem,
        :avoid_bank_conflicts


      def initialize
        set_defaults
      end

      private

      def set_defaults
        @task_fusion  = true
        @use_host_mem = true
        @avoid_bank_conflicts = true
      end

    end

    Features =  FeatureSwitcher.new
  end
end
