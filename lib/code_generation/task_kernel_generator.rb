class Hadope::TaskKernelGenerator < Struct.new(:task)

  def create_kernel
    case task
    when Hadope::Map then map_kernel
    when Hadope::Filter then filter_kernel
    else
      raise "Kernel creation not implemented for #{task.class.inspect}."
    end
  end

  private

  def map_kernel
    <<KERNEL
__kernel void #{task.name}(__global #{task.type} *data_array) {
  #{task.variable_declarations}
  #{task.setup_statements}

  #{task.body}

  #{task.return_statements}
}
KERNEL
  end

  def filter_kernel
    <<KERNEL
__kernel void #{task.name}(__global #{task.type} *data_array, __global #{task.type} *presence_array) {
  #{task.variable_declarations}
  #{task.setup_statements}

  #{task.body}

  #{task.return_statements}
}
KERNEL
  end

end
