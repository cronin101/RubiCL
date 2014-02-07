require_relative './device'

module Hadope
  class GPU < Device

    class << self
      attr_accessor :singleton

      def get
        @singleton ||= new
      end
    end

    def initialize
      @environment = initialize_GPU_environment
      super
    end

  end
end
