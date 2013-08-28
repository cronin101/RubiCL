require_relative './task'

module Hadope
  class Map < Task

    attr_reader :input_variable, :output_variable

    def initialize(input_variable, *statements)
      super()
      set_output_variable(@input_variable = input_variable)
      add_variables @input_variable
      add_statements statements.flatten
    end

    def set_output_variable(variable)
      @output_variable = variable
    end

    def to_kernel
type = 'int'
<<KERNEL
__kernel void #{self.name}(__global #{type} *data_array){
  #{@required_variables.map { |v| "#{type} #{v}" }.join(";\n  ")};
  int global_id = get_global_id(0);
  #{@input_variable} = data_array[global_id];

  #{@statements.join(";\n  ")};

  data_array[global_id] = #{@output_variable};
}
KERNEL
    end

  end
end
