require_relative './task'

module Hadope

  class TupMap < Task

    attr_reader :type

    def initialize(type, input_variables, statements)
      @type = type
      super()
      @fst_input, @snd_input = input_variables
      add_variables :tmp
      add_variables input_variables
      add_statements statements.flatten
    end

    def to_kernel
      TaskKernelGenerator.new(self).create_kernel
    end

    def statements
      [ @statements.first,
        "tmp = #@fst_input",
        "#@fst_input = fsts[global_id]",
        @statements.last,
        "#@fst_input = tmp"
      ]
    end

    def body
      statement_code
    end

    def setup_statements
      "int global_id = get_global_id(0);\n" <<
        "#@fst_input = fsts[global_id];\n"  <<
        "#@snd_input = snds[global_id];"
    end

    def return_statements
      "fsts[global_id] = #@fst_input;\n" <<
      "snds[global_id] = #@snd_input;"
    end

  end

end
