require_relative './task'

module RubiCL
  class TupFilter < Task
    attr_reader :type, :predicate

    def initialize(type, input_variables, predicate)
      @type = type
      super()
      @fst_input, @snd_input = input_variables
      add_variables input_variables
      add_statement (@predicate = predicate)
    end

    def to_kernel
      TaskKernelGenerator.new(self).create_kernel
    end

    def body
      "int flag = #{predicate} ? 1 : 0;"
    end

    def setup_statements
      "int global_id = get_global_id(0);\n" \
        "#{@fst_input} = fsts[global_id];\n"  <<
        "#{@snd_input} = snds[global_id];"
    end

    def return_statements
      'presence_array[global_id] = flag;'
    end
  end
end
