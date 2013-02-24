class HaDope::CodeGenerator
  def initialize(task)
    @task = task
  end

  def generate_kernel
    case @task
    when HaDope::Functional::Map
kernel=<<CL_KERNEL
__kernel void #{@task.name}(__global #{@task.c_key_type} *data_array){
int global_id = get_global_id(0);
#{@task.c_key_type} #{@task.key[:name]};

#{@task.key[:name]} = data_array[global_id];
#{@task.function.chomp};
data_array[global_id] = #{@task.key[:name]};
}
CL_KERNEL

    when HaDope::Functional::Filter
kernel=<<CL_KERNEL
__kernel void #{@task.name}(__global #{@task.c_key_type}* data_array, __global char* presence_array){
int global_id = get_global_id(0);
int output;
#{@task.c_key_type} #{@task.key[:name]} = data_array[global_id];
#{@task.function.chomp}
if (#{@task.test}){
presence_array[global_id] = 1;
} else {
presence_array[global_id] = 0;
}
CL_KERNEL

    else
      raise "Task type not implemented yet: #{@task.class}"
    end
  end

end
