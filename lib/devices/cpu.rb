require_relative './device'

module Hadope
  class CPU < Device

    def initialize
      @environment = initialize_CPU_environment
      super
    end

  end
end
