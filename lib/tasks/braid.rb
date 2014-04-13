require_relative './task'

module RubiCL
  class Braid < Task
    attr_reader :input_variable, :output_variable, :type

    def initialize(type, fst, snd, braid)
      @type = type
      super()
      add_variables (@output_variable = @fst = fst), (@snd = snd)
      add_statement braid
    end

    def to_kernel
      TaskKernelGenerator.new(self).create_kernel
    end

    def setup_statements
      "int global_id = get_global_id(0);\n  x = fst_array[global_id];\n  y = snd_array[global_id];"
    end

    def body
      "#{@output_variable} = #{@statements.first};"
    end

    def return_statements
      "fst_array[global_id] = #{@output_variable};"
    end
  end
end
