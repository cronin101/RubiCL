class Hadope::TaskKernelGenerator < Struct.new(:task)

  def create_kernel
    case task
    when Hadope::Map then <<KERNEL
__kernel void #{task.name}(__global #{task.type} *data_array){
  #{task.variable_declarations}
  #{task.setup_statements}

  #{task.body}

  #{task.return_statements}
}
KERNEL
    else
      raise "Kernel creation not implemented for #{task.class.inspect}."
    end
  end

end
