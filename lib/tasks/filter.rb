require_relative './task'

module Hadope
  class Filter < Task

    attr_reader :input_variable, :output_variable, :type, :predicate

    def initialize(type, input_variable, predicate)
      @type = type
      super()
      @output_variable = (@input_variable = input_variable)
      add_variables @input_variable
      add_statement (@predicate = predicate)
    end

    def fuse!(next_filter)
      add_variables next_filter.variables
      predicate = @statements.pop
      unless next_filter.input_variable == output_variable
        pipeline_variable, @output_variable = @output_variable, next_filter.output_variable
        @statements.push "#{next_filter.input_variable = pipeline_variable}"
      end
      @statements.push "(#{predicate}) && (#{next_filter.predicate})"
      self
    end

    def to_kernel
      TaskKernelGenerator.new(self).create_kernel
    end

    def predicate
      @statements.last
    end

    def body
      @statements[0..-2].join(";\n ") << ';'
      "int flag = #{predicate} ? 1 : 0;"
    end

    def return_statements
      "presence_array[global_id] = flag;"
    end

  end
end
