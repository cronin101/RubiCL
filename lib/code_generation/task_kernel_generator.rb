class Hadope::TaskKernelGenerator < Struct.new(:task)

  def create_kernel
    case task
    when Hadope::Map    then map_kernel
    when Hadope::TupMap then tupmap_kernel
    when Hadope::Filter then filter_kernel
    when Hadope::Braid  then braid_kernel
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
__kernel void #{task.name}(__global #{task.type} *data_array, __global int *presence_array) {
  #{task.variable_declarations}
  #{task.setup_statements}

  #{task.body}

  #{task.return_statements}
}
KERNEL
  end

  def tupmap_kernel
    task.instance_eval do
<<KERNEL
__kernel void #{name}(
  __global #{type} *fsts,
  __global #{type} *snds
) {
  #{variable_declarations}
  #{setup_statements}

  #{body}

  #{return_statements}
}
KERNEL
    end
  end

  def braid_kernel
    <<KERNEL
__kernel void #{task.name}(
  __global #{task.type} *fst_array,
  __global #{task.type} *snd_array
) {
  #{task.variable_declarations}
  #{task.setup_statements}

  #{task.body}

  #{task.return_statements}
}
KERNEL
  end

end
