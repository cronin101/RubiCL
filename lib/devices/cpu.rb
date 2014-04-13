require_relative './device'

module RubiCL
  class CPU < Device
    def initialize
      @environment = initialize_CPU_environment
      super
    end
  end
end
