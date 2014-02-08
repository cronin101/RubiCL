require_relative './device'

module Hadope
  class GPU < Device

    def initialize
      @environment = initialize_GPU_environment
      super
    end

  end
end
