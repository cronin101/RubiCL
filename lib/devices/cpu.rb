require_relative './device'

module Hadope
  class CPU < Device

    class << self
      attr_accessor :singleton

      def get
        @singleton ||= new
      end
    end

    def initialize
      @environment = initialize_CPU_environment
      super
    end

  end
end
