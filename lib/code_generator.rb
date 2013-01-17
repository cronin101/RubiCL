class HaDope
  class CodeGenerator
    def initialize(task)
      @task = task
    end

    def generate_kernel
      if @task.is_a? HaDope::Map
kernel=<<CL_KERNEL
__kernel void #{@task.name}(__global #{@task.c_key_type}* data_array){
int global_id = get_global_id(0);
#{@task.c_key_type} #{@task.key[:name]} = data_array[global_id];
#{@task.function.chomp}
return #{@task.key[:name]};
}
CL_KERNEL
      elsif @task.is_a? HaDope::Filter
kernel=<<CL_KERNEL
__kernel void #{@task.name}(__global #{@task.c_key_type}* data_array){
int global_id = get_global_id(0);
#{@task.c_key_type} #{@task.key[:name]} = data_array[global_id];
#{@task.function.chomp}
  if (#{@task.test}){
    return #{@task.key[:name]};
  } else {
    return NULL;
  }
}
CL_KERNEL
      else
        raise "Task type not implemented yet"
      end
    end
  end
end
