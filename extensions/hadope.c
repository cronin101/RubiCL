#include "hadope.h"

// Helper function to get error string
// *********************************************************************
const char* oclErrorString(cl_int error)
{
    static const char* errorString[] = {
        "CL_SUCCESS",
        "CL_DEVICE_NOT_FOUND",
        "CL_DEVICE_NOT_AVAILABLE",
        "CL_COMPILER_NOT_AVAILABLE",
        "CL_MEM_OBJECT_ALLOCATION_FAILURE",
        "CL_OUT_OF_RESOURCES",
        "CL_OUT_OF_HOST_MEMORY",
        "CL_PROFILING_INFO_NOT_AVAILABLE",
        "CL_MEM_COPY_OVERLAP",
        "CL_IMAGE_FORMAT_MISMATCH",
        "CL_IMAGE_FORMAT_NOT_SUPPORTED",
        "CL_BUILD_PROGRAM_FAILURE",
        "CL_MAP_FAILURE",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "CL_INVALID_VALUE",
        "CL_INVALID_DEVICE_TYPE",
        "CL_INVALID_PLATFORM",
        "CL_INVALID_DEVICE",
        "CL_INVALID_CONTEXT",
        "CL_INVALID_QUEUE_PROPERTIES",
        "CL_INVALID_COMMAND_QUEUE",
        "CL_INVALID_HOST_PTR",
        "CL_INVALID_MEM_OBJECT",
        "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR",
        "CL_INVALID_IMAGE_SIZE",
        "CL_INVALID_SAMPLER",
        "CL_INVALID_BINARY",
        "CL_INVALID_BUILD_OPTIONS",
        "CL_INVALID_PROGRAM",
        "CL_INVALID_PROGRAM_EXECUTABLE",
        "CL_INVALID_KERNEL_NAME",
        "CL_INVALID_KERNEL_DEFINITION",
        "CL_INVALID_KERNEL",
        "CL_INVALID_ARG_INDEX",
        "CL_INVALID_ARG_VALUE",
        "CL_INVALID_ARG_SIZE",
        "CL_INVALID_KERNEL_ARGS",
        "CL_INVALID_WORK_DIMENSION",
        "CL_INVALID_WORK_GROUP_SIZE",
        "CL_INVALID_WORK_ITEM_SIZE",
        "CL_INVALID_GLOBAL_OFFSET",
        "CL_INVALID_EVENT_WAIT_LIST",
        "CL_INVALID_EVENT",
        "CL_INVALID_OPERATION",
        "CL_INVALID_GL_OBJECT",
        "CL_INVALID_BUFFER_SIZE",
        "CL_INVALID_MIP_LEVEL",
        "CL_INVALID_GLOBAL_WORK_SIZE",
    };

    const int errorCount = sizeof(errorString) / sizeof(errorString[0]);

    const int index = -error;

    return (index >= 0 && index < errorCount) ? errorString[index] : "";

}

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

HadopeTask buildTaskFromSource(const HadopeEnvironment env, const char* kernel_source, const size_t source_size, char* name){
  HadopeTask task;
  cl_int ret;

  task.name = name;
  task.program = clCreateProgramWithSource(env.context, 1, (const char **) &kernel_source, &source_size, &ret);
  printf("clCreateProgramWithSource %s\n", oclErrorString(ret));
  ret = clBuildProgram(task.program, 1, &env.device_id, NULL, NULL, NULL);
  printf("clBuildProgram %s\n", oclErrorString(ret));
  task.kernel = clCreateKernel(task.program, task.name, &ret);
  printf("clCreateKernel %s\n", oclErrorString(ret));

  return task;
}

void loadIntArrayIntoDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct, const int *dataset){
  cl_int ret;
  ret = clEnqueueWriteBuffer(env.queue, mem_struct.buffer, CL_TRUE, 0, mem_struct.buffer_size * sizeof(int), dataset, 0, NULL, NULL);
  printf("clEnqueueWriteBuffer %s\n", oclErrorString(ret));
}

void getIntArrayFromDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct, int *dataset){
  cl_int ret;
  int i;
  clEnqueueReadBuffer(env.queue, mem_struct.buffer, CL_TRUE, 0, mem_struct.buffer_size * sizeof(int), dataset, 0, NULL, NULL);
  printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));
}

void runTaskOnCurrentDataset(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct, const HadopeTask task){
  cl_int ret;
  size_t g_work_size[3] = {mem_struct.buffer_size, 0, 0};
  size_t l_work_size[3] = {mem_struct.buffer_size, 0, 0};

  ret = clSetKernelArg(task.kernel, 0, sizeof(cl_mem) , &mem_struct.buffer);
  printf("clSetKernelArg %s\n", oclErrorString(ret));
  ret = clEnqueueNDRangeKernel(env.queue, task.kernel, 1, NULL, g_work_size, l_work_size, 0, NULL, NULL);
  printf("clEnqueueNDRangeKernel %s\n", oclErrorString(ret));

}
