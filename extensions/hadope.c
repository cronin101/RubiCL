#include "hadope.h"

HadopeEnvironment createHadopeEnvironment(){
  HadopeEnvironment env;
  cl_platform_id platform_id = NULL;
  cl_uint ret_num_platforms;
  cl_uint ret_num_devices;
  cl_int ret;

  ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
  ret = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_DEFAULT,
                        1, &env.device_id, &ret_num_devices);
  env.context = clCreateContext(NULL, 1, &env.device_id, NULL, NULL, &ret);
  env.queue = clCreateCommandQueue(env.context, env.device_id, 0, &ret);

  return env;
}

cl_mem createMemoryBuffer(const HadopeEnvironment env, const int required_memory){
  cl_int ret;

  return clCreateBuffer(env.context, CL_MEM_READ_WRITE, required_memory, NULL, &ret);
}

HadopeTask buildTaskFromSource(const HadopeEnvironment env, const char* kernel_source, const size_t source_size, char* name){
  HadopeTask task;
  cl_int ret;

  task.name = name;
  ret = clBuildProgram(task.program, 1, &env.device_id, NULL, NULL, NULL);
  task.kernel = clCreateKernel(task.program, task.name, &ret);

  return task;
}

void loadIntArrayIntoDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct, const int *dataset){
  clEnqueueWriteBuffer(env.queue, mem_struct.buffer, CL_TRUE, 0, mem_struct.buffer_size * sizeof(int), dataset, 0, NULL, NULL);
}

void getIntArrayFromDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct, int *dataset){
  clEnqueueReadBuffer(env.queue, mem_struct.buffer, CL_TRUE, 0, mem_struct.buffer_size * sizeof(int), dataset, 0, NULL, NULL);
}
