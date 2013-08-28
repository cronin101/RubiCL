require_relative './task'

module Hadope
  class Map < Task

    attr_reader :input_name, :output_name

    def initialize(input_name, *statements)
      super()
      set_output_name(@input_name = input_name)
      add_statements statements.flatten
    end

    def set_output_name(name)
      @output_name = name
    end

    def to_kernel
type = 'int'
<<KERNEL
__kernel void #{self.name}(__global #{type} *data_array){
  int global_id = get_global_id(0);
  #{type} #{@input_name} = data_array[global_id];

  #{@statements.join(";\n  ")};

  data_array[global_id] = #{@output_name};
}
KERNEL
    end

  end
end
