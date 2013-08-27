require_relative './task'

module Hadope
  class Map < Task

    attr_reader :element_name

    def initialize(element_name, *statements)
      super()
      @element_name = element_name
      add_statments statements
    end

  end
end
