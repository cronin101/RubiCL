class HaDope
  class CodeGenerator
    def initialize(task)
      @task = task
    end

    def generate_kernel
      if @task.is_a? HaDope::Map
kernel=<<CL_KERNEL
__kernel void #{@task.name}(__global #{@task.c_key_type} *data_array){
int global_id = get_global_id(0);
#{@task.c_key_type} #{@task.key[:name]};

#{@task.key[:name]} = data_array[global_id];
#{@task.function.chomp};
data_array[global_id] = #{@task.key[:name]};
}
CL_KERNEL
      elsif @task.is_a? HaDope::Filter
kernel=<<CL_KERNEL
__kernel void #{@task.name}(__global #{@task.c_key_type}* data_array){
int global_id = get_global_id(0);
int output;
#{@task.c_key_type} #{@task.key[:name]} = data_array[global_id];
#{@task.function.chomp}
if (#{@task.test}){
  output = #{@task.key[:name]};
} else {
  output = NULL;
}
data_array[global_id] = output;
}
CL_KERNEL
      else
        raise "Task type not implemented yet"
      end
    end
  end
end
