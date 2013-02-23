#include "hadope.h"

HadopeEnvironment createHadopeEnvironment(const cl_device_type device_type){
  HadopeEnvironment env;
  cl_platform_id platform_id = NULL;
  cl_uint ret_num_platforms;
  cl_uint ret_num_devices;
  cl_int ret;

  ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
  ret = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_CPU,
                        1, &env.device_id, &ret_num_devices);
  printf("clGetDeviceIDs %s\n", oclErrorString(ret));
  env.context = clCreateContext(NULL, 1, &env.device_id, NULL, NULL, &ret);
  printf("clCreateContext %s\n", oclErrorString(ret));
  env.queue = clCreateCommandQueue(env.context, env.device_id, 0, &ret);
  printf("clCreateCommandQueue %s\n", oclErrorString(ret));

  return env;
}

cl_mem createMemoryBuffer(const HadopeEnvironment env, const int required_memory){
  cl_int ret;
  cl_mem buffer;

  buffer = clCreateBuffer(env.context, CL_MEM_READ_WRITE, required_memory, NULL, &ret);
  printf("clCreateBuffer %s\n", oclErrorString(ret));

  return buffer;
}

HadopeTask buildTaskFromSource(const HadopeEnvironment env, const char* kernel_source,
                                                const size_t source_size, char* name){
  HadopeTask task;
  cl_int ret;

  task.name = name;
  task.program = clCreateProgramWithSource(env.context, 1, (const char **) &kernel_source,
                                                                      &source_size, &ret);
  printf("clCreateProgramWithSource %s\n", oclErrorString(ret));
  ret = clBuildProgram(task.program, 1, &env.device_id, NULL, NULL, NULL);
  printf("clBuildProgram %s\n", oclErrorString(ret));
  task.kernel = clCreateKernel(task.program, task.name, &ret);
  printf("clCreateKernel %s\n", oclErrorString(ret));

  return task;
}

void loadIntArrayIntoDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                                        const int *dataset){
  cl_int ret;
  ret = clEnqueueWriteBuffer(env.queue, mem_struct.buffer, CL_TRUE, 0,
        mem_struct.buffer_entries * sizeof(int), dataset, 0, NULL, NULL);
  printf("clEnqueueWriteBuffer %s\n", oclErrorString(ret));
}

void getIntArrayFromDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                                              int *dataset){
  cl_int ret;
  int i;
  clEnqueueReadBuffer(env.queue, mem_struct.buffer, CL_TRUE, 0,
        mem_struct.buffer_entries * sizeof(int), dataset, 0, NULL, NULL);
  printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));
}

void runTaskOnCurrentDataset(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                                       const HadopeTask task){
  cl_int ret;
  size_t g_work_size[3] = {mem_struct.buffer_entries, 0, 0};

  ret = clSetKernelArg(task.kernel, 0, sizeof(cl_mem) , &mem_struct.buffer);
  printf("clSetKernelArg %s\n", oclErrorString(ret));
  ret = clEnqueueNDRangeKernel(env.queue, task.kernel, 1, NULL, g_work_size, NULL, 0, NULL,
                                                                                     NULL);
  printf("clEnqueueNDRangeKernel %s\n", oclErrorString(ret));

}
