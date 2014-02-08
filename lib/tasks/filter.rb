require_relative './task'

module Hadope
  class Filter < Task

    attr_reader :input_variable, :output_variable, :type

    def initialize(type, input_variable, predicate)
      @type = type
      super()
      add_variables @input_variable = input_variable
      add_statement predicate
    end

    def to_kernel
      TaskKernelGenerator.new(self).create_kernel
    end

    def body
      "int flag = #{@statements.first} ? 1 : 0;"
    end

    def return_statements
      "presence_array[global_id] = flag;"
    end

  end
end
