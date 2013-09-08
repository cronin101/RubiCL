require_relative './task'

module Hadope
  class Map < Task

    attr_reader :input_variable, :output_variable

    def initialize(input_variable, *statements)
      super()
      @output_variable = (@input_variable = input_variable)
      add_variables @input_variable
      add_statements statements.flatten
    end

    def fuse!(next_map)
      conversion =  if next_map.input_variable == output_variable
                      [] # No variable pipelining required!
                    else
                      pipeline_variable = output_variable
                      @output_variable = next_map.output_variable
                      add_variables next_map.input_variable
                      ["#{next_map.input_variable} = #{pipeline_variable}"]
                    end
      add_statements(conversion + next_map.statements)
    end

    def to_kernel
      TaskKernelGenerator.new(self).create_kernel
    end

    def type
      'int4'
    end

    def body
      @statements.join(";\n  ") << ';'
    end

    def return_statements
      "data_array[global_id] = #{@output_variable};"
    end

  end
end
