class RubiCL::TaskKernelGenerator < Struct.new(:task)

  def create_kernel
    task_type = task.class.to_s.split('::').last.downcase
    begin
      send "#{task_type}_kernel"
    rescue NoMethodError
      raise "Kernel creation not implemented for #{task.class.inspect}."
    end
  end

  private

  alias_method :smap_kernel, def map_kernel
    <<KERNEL
__kernel void #{task.name}(__global #{task.type} *data_array) {
  #{task.variable_declarations}
  #{task.setup_statements}

  #{task.body}

  #{task.return_statements}
}
KERNEL
  end

  alias_method :mappingfilter_kernel, def filter_kernel
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

  def tupfilter_kernel
    task.instance_eval do
<<KERNEL
__kernel void #{name}(
  __global #{type} *fsts, __global #{type} *snds,
  __global int *presence_array
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
