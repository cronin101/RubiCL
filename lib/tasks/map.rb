require_relative './task'

module Hadope
  class Map < Task

    attr_reader :input_name, :output_name

    def initialize(input_name, *statements)
      super()
      set_output_name(@input_name = input_name)
      add_statements statements
    end

    def set_output_name(name)
      @output_name = name
    end

  end
end
