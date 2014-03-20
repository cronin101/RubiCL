class Hadope::TaskKernelGenerator < Struct.new(:task)

  def create_kernel
    case task
    when Hadope::Map    then map_kernel
    when Hadope::Filter then filter_kernel
    when Hadope::Braid  then braid_kernel
    else
      raise "Kernel creation not implemented for #{task.class.inspect}."
    end
  end

  private

  def map_kernel
    <<KERNEL
__kernel void #{task.name}(__global #{task.type} *data_array, const uint width, const uint elements) {
  #{task.variable_declarations}

  int global_id, loop_start, loop_finish, next_start, num_elements;
  global_id = get_global_id(0);
  loop_start = global_id * width;
  next_start = ((global_id + 1) * width);
  num_elements = elements;
  loop_finish = min(next_start, num_elements) - 1;

  for(global_id = loop_start; global_id <= loop_finish; ++global_id) {
    #{task.setup_statements}
    #{task.body}
    #{task.return_statements}
  }

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
