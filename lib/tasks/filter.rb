require_relative './task'

module Hadope
  class Filter < Task

    attr_reader :input_variable, :output_variable

    def initialize(input_variable, predicate)
      super()
      add_variables @output_variable = @input_variable = input_variable
      add_statement predicate
    end

    def to_kernel
      TaskKernelGenerator.new(self).create_kernel
    end

    def type
      'int'
    end

    def body
      "#{@output_variable} = #{@statements.first} ? 1 : 0;"
    end

    def return_statements
      "presence_array[global_id] = #{@output_variable}"
    end

  end
end
