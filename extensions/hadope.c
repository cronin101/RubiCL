#include "hadope.h"

/* ~~ Init Methods ~~ */

/* Finds target device then creates context and command queue, packages in HadopeEnvironment and returns.
 *
 * @device_type: CL_DEVICE_TYPE_GPU / CL_DEVICE_TYPE_CPU */
HadopeEnvironment
createHadopeEnvironment(const cl_device_type device_type){
  HadopeEnvironment env;
  cl_platform_id platform_id = NULL;
  cl_uint ret_num_platforms;
  cl_uint ret_num_devices;
  cl_int ret;

  /* Find device of target type on current platform and store device_id */
  ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
  ret = clGetDeviceIDs(platform_id, device_type,
                        1, &env.device_id, &ret_num_devices);
  printf("clGetDeviceIDs %s\n", oclErrorString(ret));

  /* Create OpenCL context for target device and store in environment*/
  env.context = clCreateContext(NULL, 1, &env.device_id, NULL, NULL, &ret);
  printf("clCreateContext %s\n", oclErrorString(ret));

  /* Create command queue for context/target-device and store in environment */
  env.queue = clCreateCommandQueue(env.context, env.device_id, 0, &ret);
  printf("clCreateCommandQueue %s\n", oclErrorString(ret));

  return env;
}

/* ~~ END Init Methods ~~ */

/* Device Memory Management Methods ~~ */

/* Creates a cl_mem buffer with a given memory capacity and given access flags.
 *
 * @env: Struct containing device/context/queue variables.
 * @req_memory: The size of the memory buffer to create.
 * @fs: Flags to set on memory buffer... CL_MEM_READ_WRITE/CL_MEM_READ. */
cl_mem
createMemoryBuffer(const HadopeEnvironment env, const int req_memory, const cl_mem_flags fs){
  cl_int ret;
  cl_mem buffer;

  buffer = clCreateBuffer(env.context, fs, req_memory, NULL, &ret);
  printf("clCreateBuffer %s\n", oclErrorString(ret));

  return buffer;
}

/* Writes the contents of a given dataset into a given cl_mem device memory buffer
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing cl_mem buffer and the number of entries it can hold.
 * @dataset: Pointer to an integer array of data to be read, same length as buffer. */
void
loadIntArrayIntoDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                                    const int *dataset){
  cl_int ret;

  ret = clEnqueueWriteBuffer(env.queue, mem_struct.buffer, CL_TRUE, 0,
        (mem_struct.buffer_entries * sizeof(int)), dataset, 0, NULL, NULL);
  printf("clEnqueueWriteBuffer %s\n", oclErrorString(ret));
}

/* Reads the contents of device memory buffer into a given dataset array
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing cl_mem buffer and the number of entries it can hold.
 * @dataset: Pointer to an integer array of data to be written, same length as buffer */
void
getIntArrayFromDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                                         int *dataset){
  cl_int ret;

  ret = clEnqueueReadBuffer(env.queue, mem_struct.buffer, CL_TRUE, 0,
    mem_struct.buffer_entries * sizeof(int), dataset, 0, NULL, NULL);
  printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));
}

/* Reads the contents of a calculated 'presence array' from device memory buffer
 * into given output array.
 * A presence array is an array of boolean flags denoting which elements of an
 * input dataset passed a given predicate.
 *
 * @env: Struct containing device/context/queue variables.
 * @presence: Struct containing device presence-buffer and its length.
 * @presence_array: Pointer to array of int flags to be copied from device buffer. */
void
getPresencearrayFromDevice(const HadopeEnvironment env, const HadopeMemoryBuffer presence,
                                                                      int *presence_array){
  cl_int ret;
  ret = clEnqueueReadBuffer(env.queue, presence.buffer, CL_TRUE, 0, presence.buffer_entries * sizeof(int),
                                                                           presence_array, 0, NULL, NULL);
  printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));
}

/* ~~ END Memory Management Methods ~~ */

/* ~~ Task Compilation Methods ~~ */

/* Takes the source code for a kernel and the name of the task to build and creates a
 * HadopeTask Struct containing the components needed to dispatch this task later.
 *
 * @env: Struct containing device/context/queue variables.
 * @kernel_source: String containing the .cl Kernel source.
 * @source_size: The size of the source.
 * @name: The name of the task within the source to build. */
HadopeTask
buildTaskFromSource(const HadopeEnvironment env, const char* kernel_source,
                                     const size_t source_size, char* name){
  HadopeTask task;
  cl_int ret;

  /* Create cl_program from given task/name and store inside HadopeTask struct. */
  task.name = name;
  task.program = clCreateProgramWithSource(env.context, 1, (const char **) &kernel_source,
                                                                      &source_size, &ret);
  printf("clCreateProgramWithSource %s\n", oclErrorString(ret));

  /* Create kernel from cl_program to execute later on target-device */
  ret = clBuildProgram(task.program, 1, &env.device_id, NULL, NULL, NULL);
  printf("clBuildProgram %s\n", oclErrorString(ret));
  task.kernel = clCreateKernel(task.program, task.name, &ret);
  printf("clCreateKernel %s\n", oclErrorString(ret));

  return task;
}

/* ~~ END Task Compilation Methods ~~ */

/* ~~ Task Dispatching Methods ~~ */

/* Enqueues a given task to operate on a given memory buffer dataset.
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing cl_mem buffer / target dataset.
 * @task: Struct containing the kernel to execute and the task name. */
void
runTaskOnDataset(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                           const HadopeTask task){
  cl_int ret;
  size_t g_work_size[3] = {mem_struct.buffer_entries, 0, 0};

  /* Kernel's global data_array set to be the given device memory buffer */
  ret = clSetKernelArg(task.kernel, 0, sizeof(cl_mem), &mem_struct.buffer);
  printf("clSetKernelArg %s\n", oclErrorString(ret));

  /* Kernel enqueued to be executed on the environment's command queue */
  ret = clEnqueueNDRangeKernel(env.queue, task.kernel, 1, NULL, g_work_size,
                                                       NULL, 0, NULL, NULL);
  printf("clEnqueueNDRangeKernel %s\n", oclErrorString(ret));
}

/* Enqueues a task to compute the presence array for a given dataset and filter kernel.
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing the dataset/size of data to filter.
 * @task: HadopeTask containing the kernel to set flags if the predicate is satisfied.
 * @presence: Pointer to HadopeMemoryBuffer struct, to be assigned the presence_array */
void
computePresenceArrayForDataset(const HadopeEnvironment env,
                                          const HadopeMemoryBuffer mem_struct,
            const HadopeTask task, HadopeMemoryBuffer *presence){
  cl_int ret;
  size_t g_work_size[3] = {mem_struct.buffer_entries, 0, 0};

  /* Kernel's global data_array set to be the given device memory buffer */
  ret = clSetKernelArg(task.kernel, 0, sizeof(cl_mem), &mem_struct.buffer);
  printf("clSetKernelArg %s\n", oclErrorString(ret));

  /* Output buffer created to be an int flag for each element in input dataset. */
  presence->buffer_entries = mem_struct.buffer_entries;
  presence->buffer = createMemoryBuffer(env, (presence->buffer_entries * sizeof(int)),
                                                                  CL_MEM_READ_WRITE);

  /* Kernel's global presence_array set to be the newly created presence buffer */
  ret = clSetKernelArg(task.kernel, 1, sizeof(cl_mem), &presence->buffer);
  printf("clSetKernelArg PA %s\n", oclErrorString(ret));

  /* Kernel enqueued to be executed on the enviornment's command queue */
  ret = clEnqueueNDRangeKernel(env.queue, task.kernel, 1, NULL, g_work_size, NULL, 0, NULL,
                                                                                     NULL);
  printf("clEnqueueNDRangeKernel %s\n", oclErrorString(ret));
}

/* ~~ END Task Dispatching Methods ~~ */
