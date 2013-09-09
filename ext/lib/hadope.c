#include "./hadope.h"
#include "prefix_sum/prescan.h"
#include "oclerrorexplain.h"

#define DEBUG 1

void releaseMemoryCallback(
  cl_event event,
  cl_int event_command_exec_status,
  void* memory
) {
  free(memory);
}

void setGroupSize(
  const HadopeEnvironment env
) {
  size_t max_workgroup_size = 0;
  size_t returned_size = 0;
  cl_int ret = clGetDeviceInfo(
    env.device_id,
    CL_DEVICE_MAX_WORK_GROUP_SIZE,
    sizeof(size_t),
    &max_workgroup_size,
    &returned_size
  );

  if (ret != CL_SUCCESS) printf("clGetDeviceInfo %s\n", oclErrorString(ret));
  GROUP_SIZE = min(GROUP_SIZE,  max_workgroup_size);
}

void displayDeviceInfo(cl_device_type type) {
  cl_uint num_devices, i;
  clGetDeviceIDs(NULL, type, 0, NULL, &num_devices);

  cl_device_id* devices = calloc(sizeof(cl_device_id), num_devices);
  clGetDeviceIDs(NULL, type, num_devices, devices, NULL);

  char buf[128];
  size_t max_workgroup_size;
  for (i = 0; i < num_devices; i++) {
    clGetDeviceInfo(devices[i], CL_DEVICE_VENDOR, 128, buf, NULL);
    printf("* Device %d: %s ", (i + 1), buf);
    clGetDeviceInfo(devices[i], CL_DEVICE_NAME, 128, buf, NULL);
    printf("%s\n", buf);
    clGetDeviceInfo(devices[i], CL_DEVICE_VERSION, 128, buf, NULL);
    printf("\tSupports: %s\n", buf);
    clGetDeviceInfo(devices[i], CL_DEVICE_MAX_WORK_GROUP_SIZE, 128, &max_workgroup_size, NULL);
    printf("\tMax workgroup size: %lu\n", max_workgroup_size);
  }

  free(devices);
}

/* ~~ Init Methods ~~ */

/* Selects target device then creates context and command queue, packages in HadopeEnvironment and returns.
 *
 * @device_type: CL_DEVICE_TYPE_GPU / CL_DEVICE_TYPE_CPU */
HadopeEnvironment createHadopeEnvironment(const cl_device_type device_type) {
  HadopeEnvironment env;
  cl_platform_id platform;
  cl_int ret;

  /* Selecting an OpenCL platform */
  cl_uint num_platforms, i;
  ret = clGetPlatformIDs(
    0,             // Limit
    NULL,          // Value destination
    &num_platforms // Count destination
  );
  cl_platform_id* platforms = calloc(sizeof(cl_platform_id), num_platforms);
  ret = clGetPlatformIDs(
    num_platforms, // Limit
    platforms,     // Value destination
    NULL           // Count destination
  );
  if (ret != CL_SUCCESS) printf("clGetPlatformIDs %s\n", oclErrorString(ret));

  if (DEBUG) {
    char buf [128];
    for (i = 0; i < num_platforms; i++) {
      ret = clGetPlatformInfo(
        platforms[i],        // Platform
        CL_PLATFORM_VERSION, // OpenCL version
        sizeof(buf),         // Buffer size
        buf,                 // Destination buffer
        NULL                 // Size destination
      );
      printf("* Platform %d: %s", (i + 1), buf);

      ret = clGetPlatformInfo(
        platforms[i],        // Platform
        CL_PLATFORM_NAME,    // Platform name
        sizeof(buf),         // Buffer size
        buf,                 // Destination buffer
        NULL                 // Size destination
      );
      printf(" %s", buf);

      ret = clGetPlatformInfo(
        platforms[i],        // Platform
        CL_PLATFORM_VENDOR,  // Platform vendor
        sizeof(buf),         // Buffer size
        buf,                 // Destination buffer
        NULL                 // Size destination
      );
      printf(" %s\n", buf);
    }
  }

  if (DEBUG) printf("Selecting Platform 1.\n");
  platform = platforms[0];
  free(platforms);

  /* Selecting a device */
  cl_uint num_devices;
  ret = clGetDeviceIDs(
    platform,    // Selected platform
    device_type, // Type of device (CPU/GPU)
    0,           // Limit
    NULL,        // Devices destination
    &num_devices // Count destination
  );

  cl_device_id* devices = calloc(sizeof(cl_device_id), num_devices);
  ret = clGetDeviceIDs(
    platform,    // Selected platform
    device_type, // Type of device (CPU/GPU)
    num_devices, // Limit
    devices,     // Devices destination
    NULL         // Count destination
  );
  if (ret != CL_SUCCESS) printf("clGetDeviceIDs %s\n", oclErrorString(ret));

  if (DEBUG) {
    displayDeviceInfo(device_type);
    printf("Selecting Device 1.\n");
  }
  env.device_id = devices[0];
  free(devices);

  /* Create OpenCL context for target device and store in environment*/
  env.context = clCreateContext(
    NULL,           // Context properties to set
    1,              // Number of devices specified
    &env.device_id, // Device specified
    NULL,           // Error callback function
    NULL,           // User data specified
    &ret            // Status destination
  );
  if (ret != CL_SUCCESS) printf("clCreateContext %s\n", oclErrorString(ret));

  /* Create command queue for context/target-device and store in environment */
  env.queue = clCreateCommandQueue(
    env.context,   // Context to use
    env.device_id, // Device to send commands to
    0,             // Queue properties bitfield, neither out_of_order nor profiling flags set.
    &ret           // Status destination
  );
  if (ret != CL_SUCCESS) printf("clCreateCommandQueue %s\n", oclErrorString(ret));

  /* Record the maximum supported group size. */
  setGroupSize(env);

  return env;
}

/* ~~ END Init Methods ~~ */

/* Device Memory Management Methods ~~ */

/* Creates a cl_mem buffer with a given memory capacity and given access flags.
 *
 * @env: Struct containing device/context/queue variables.
 * @req_memory: The size of the memory buffer to create.
 * @fs: Flags to set on memory buffer... CL_MEM_READ_WRITE/CL_MEM_READ. */
cl_mem createMemoryBuffer(
  const HadopeEnvironment env,
  const size_t req_memory,
  const cl_mem_flags flags
) {
  cl_int ret;
  cl_mem buffer = clCreateBuffer(
    env.context, // Context to use
    flags,       // cl_mem_flags set
    req_memory,  // Size of buffer
    NULL,        // Prexisting data
    &ret         // Status destination
  );
  if (ret != CL_SUCCESS) printf("clCreateBuffer %s\n", oclErrorString(ret));

  return buffer;
}

/* Writes the contents of a given dataset into a given cl_mem device memory buffer
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing cl_mem buffer and the number of entries it can hold.
 * @dataset: Pointer to an integer array of data to be read, same length as buffer. */
void loadIntArrayIntoDevice(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  int* dataset
) {
  cl_event write_event;
  cl_int ret = clEnqueueWriteBuffer(
    env.queue,                                 // Command queue
    mem_struct.buffer,                         // Memory buffer
    CL_FALSE,                                  // Blocking write? (set to nonblocking)
    0,                                         // Offset in buffer to write to
    mem_struct.buffer_entries * sizeof(int),   // Input data size
    dataset,                                   // Input data
    0,                                         // Number of preceding actions
    NULL,                                      // List of preceding actions
    &write_event                               // Event object destination
  );

  if (ret != CL_SUCCESS) printf("clEnqueueWriteBuffer %s\n", oclErrorString(ret));

  clSetEventCallback(
    write_event,            // Event to monitor
    CL_COMPLETE,            // Status to fire on
    &releaseMemoryCallback, // Callback to trigger
    dataset                 // Data to pass to callback
  );

}

/* Reads the contents of device memory buffer into a given dataset array
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing cl_mem buffer and the number of entries it can hold.
 * @dataset: Pointer to an integer array of data to be written, same length as buffer */
void getIntArrayFromDevice(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  int *dataset
) {
  /* Wait for pending actions to complete */
  clFinish(env.queue);

  cl_int ret = clEnqueueReadBuffer(
    env.queue,                               // Device's command queue
    mem_struct.buffer,                       // Buffer to output data from
    CL_TRUE,                                 // Block? Makes no sense to be asynchronous here
    0,                                       // Offset to read from
    mem_struct.buffer_entries * sizeof(int), // Size of output data
    dataset,                                 // Output destination
    0,                                       // Number of preceding actions
    NULL,                                    // List of preceding actions
    NULL                                     // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));
}

void releaseTemporaryFilterBuffers(
  HadopeMemoryBuffer* presence,
  HadopeMemoryBuffer* index_scan
) {
  clReleaseMemObject(presence->buffer);
  clReleaseMemObject(index_scan->buffer);
}

void releaseDeviceDataset(
  HadopeMemoryBuffer* dataset
) {
  clReleaseMemObject(dataset->buffer);
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
HadopeTask buildTaskFromSource(
  const HadopeEnvironment env,
  const char* kernel_source,
  const size_t source_size,
  char* name
) {
  HadopeTask task;
  cl_int ret;

  /* Create cl_program from given task/name and store inside HadopeTask struct. */
  task.name = name;
  task.program = clCreateProgramWithSource(
    env.context,                    // Context
    1,                              // Number of parts that the source is in
    (const char **) &kernel_source, // Array of program source code
    &source_size,                   // Total size of source
    &ret                            // Status destination
  );
  if (ret != CL_SUCCESS) printf("clCreateProgramWithSource %s\n", oclErrorString(ret));

  /* Create kernel from cl_program to execute later on target-device */
  ret = clBuildProgram(
    task.program,            // Program to build
    1,                       // Number of devices involved
    &env.device_id,          // List of involved devices
    "-cl-fast-relaxed-math", // Compilation options
    NULL,                    // Build complete callback, building is synchronous if omitted
    NULL                     // Callback user data
  );
  if (ret != CL_SUCCESS) printf("clBuildProgram %s\n", oclErrorString(ret));

  task.kernel = clCreateKernel(
    task.program, // Built program
    task.name,    // Entry point to kernel
    &ret          // Status destination
  );
  if (ret != CL_SUCCESS) printf("clCreateKernel %s\n", oclErrorString(ret));

  return task;
}

/* ~~ END Task Compilation Methods ~~ */

/* ~~ Task Dispatching Methods ~~ */

/* Enqueues a given task to operate on a given memory buffer dataset.
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing cl_mem buffer / target dataset.
 * @task: Struct containing the kernel to execute and the task name. */
void runTaskOnDataset(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  const HadopeTask task
) {
  size_t g_work_size[1] = {ceil((float) mem_struct.buffer_entries / 4)};

  /* Kernel's global data_array set to be the given device memory buffer */
  cl_int ret = clSetKernelArg(
    task.kernel,       // Kernel concerned
    0,                 // Index of argument to specify
    sizeof(cl_mem),    // Size of argument value
    &mem_struct.buffer // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  /* Kernel enqueued to be executed on the environment's command queue */
  ret = clEnqueueNDRangeKernel(
    env.queue,   // Device's command queue
    task.kernel, // Kernel to enqueue
    1,           // Dimensionality of work
    0,           // Global offset of work index
    g_work_size, // Array of work sizes by dimension
    NULL,        // Local work size, omitted so will be automatically deduced
    0,           // Number of preceding events
    NULL,        // Preceding events list
    NULL         // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueNDRangeKernel %s\n", oclErrorString(ret));
}

/* Enqueues a task to compute the presence array for a given dataset and filter kernel.
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing the dataset/size of data to filter.
 * @task: HadopeTask containing the kernel to set flags if the predicate is satisfied.
 * @presence: Pointer to HadopeMemoryBuffer struct, to be assigned the presence_array */
void computePresenceArrayForDataset(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  const HadopeTask task,
  HadopeMemoryBuffer *presence
) {
  size_t g_work_size[1] = {ceil((float)mem_struct.buffer_entries/4)};

  /* Kernel's global data_array set to be the given device memory buffer */
  cl_int ret = clSetKernelArg(
    task.kernel,       // Kernel concerned
    0,                 // Index of argument to specify
    sizeof(cl_mem),    // Size of argument value
    &mem_struct.buffer // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  /* Output buffer created to be an int flag for each element in input dataset. */
  presence->buffer_entries = mem_struct.buffer_entries;
  presence->buffer = createMemoryBuffer(
    env,                                      // Environment struct
    (presence->buffer_entries * sizeof(int)), // Size of buffer to create
    CL_MEM_HOST_READ_ONLY                     // Buffer flags set
  );

  /* Kernel's global presence_array set to be the newly created presence buffer */
  ret = clSetKernelArg(
    task.kernel,      // Kernel concerned
    1,                // Index of argument to specify
    sizeof(cl_mem),   // Size of argument value
    &presence->buffer // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg PA %s\n", oclErrorString(ret));

  /* Kernel enqueued to be executed on the environment's command queue */
  ret = clEnqueueNDRangeKernel(
    env.queue,   // Device's command queue
    task.kernel, // Kernel to enqueue
    1,           // Dimensionality of work
    0,           // Global offset of work index
    g_work_size, // Array of work size in each dimension
    NULL,        // Local work size, omitted so will be deduced by OpenCL platform
    0,           // Number of preceding events
    NULL,        // Preceding events list
    NULL         // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueNDRangeKernel %s\n", oclErrorString(ret));
}

HadopeMemoryBuffer exclusivePrefixSum(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer presence
) {
  int i;
  cl_int ret;
  HadopeMemoryBuffer output_struct;

  cl_mem output_buffer = clCreateBuffer(
    env.context,
    CL_MEM_HOST_READ_ONLY,
    presence.buffer_entries * sizeof(int),
    NULL,
    NULL
  );

  const char* prescan_filename = "./ext/lib/prefix_sum/scan_kernel.cl";
  char *source = LoadProgramSourceFromFile(prescan_filename);
  if (!source) printf("Error loading '%s' source.\n", prescan_filename);

  ComputeProgram = clCreateProgramWithSource(
    env.context,
    1,
    (const char **) &source,
    NULL,
    &ret
  );
  if (ret != CL_SUCCESS) printf("clCreateProgramWithSource %s\n", oclErrorString(ret));

  ret = clBuildProgram(
    ComputeProgram,
    1,                       // Number of devices involved
    &env.device_id,          // List of involved devices
    "-cl-fast-relaxed-math", // Compilation options
    NULL,                    // Build complete callback, building is synchronous if omitted
    NULL                     // Callback user data
  );
  if (ret != CL_SUCCESS) printf("clBuildProgram %s\n", oclErrorString(ret));

  ComputeKernels = (cl_kernel*) calloc(KernelCount, sizeof(cl_kernel));

  for(i = 0; i < KernelCount; i++) {
    ComputeKernels[i] = clCreateKernel(
      ComputeProgram,
      KernelNames[i],
      &ret
    );
    if (!ComputeKernels[i] || ret != CL_SUCCESS) printf("clCreateKernel %s\n", oclErrorString(ret));

    size_t wgSize;
    ret = clGetKernelWorkGroupInfo(
      ComputeKernels[i],
      env.device_id,
      CL_KERNEL_WORK_GROUP_SIZE,
      sizeof(size_t),
      &wgSize,
      NULL
    );
    if (ret != CL_SUCCESS) printf("clGetKernelWorkGroupInfo %s\n", oclErrorString(ret));
    GROUP_SIZE = min(GROUP_SIZE, wgSize);
  }

  free(source);

  CreatePartialSumBuffers(presence.buffer_entries, env.context);
  PreScanBuffer(env.queue, output_buffer, presence.buffer, GROUP_SIZE, GROUP_SIZE, presence.buffer_entries);

  ret = clFinish(env.queue);
  if (ret != CL_SUCCESS) printf("clFinish %s\n", oclErrorString(ret));

  ReleasePartialSums();
  for(i = 0; i < KernelCount; i++) clReleaseKernel(ComputeKernels[i]);
  clReleaseProgram(ComputeProgram);

  output_struct.buffer_entries = presence.buffer_entries;
  output_struct.buffer = output_buffer;

  return output_struct;
}

HadopeMemoryBuffer filterByScatteredWrites(
  const HadopeEnvironment env,
  HadopeMemoryBuffer input_dataset,
  HadopeMemoryBuffer presence,
  HadopeMemoryBuffer index_scan
) {
  cl_int ret;
  HadopeMemoryBuffer filtered_dataset;
  int index_reduce, last_element_presence;
  ret = clEnqueueReadBuffer(
    env.queue,                                     // Device's command queue
    index_scan.buffer,                             // Buffer to output data from
    CL_FALSE,                                      // Block? Async to hide latency
    (index_scan.buffer_entries - 1) * sizeof(int), // Offset to read from
    sizeof(int),                                   // Size of output data
    &index_reduce,                                 // Output destination
    0,                                             // Number of preceding actions
    NULL,                                          // List of preceding actions
    NULL                                           // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));

  ret = clEnqueueReadBuffer(
    env.queue,                                   // Device's command queue
    presence.buffer,                             // Buffer to output data from
    CL_FALSE,                                    // Block? Async to hide latency
    (presence.buffer_entries - 1) * sizeof(int), // Offset to read from
    sizeof(int),                                 // Size of output data
    &last_element_presence,                      // Output destination
    0,                                           // Number of preceding actions
    NULL,                                        // List of preceding actions
    NULL                                         // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));

  /* Build kernel whilst data is being fetched from device */
  const char* scatter_filename = "./ext/lib/scatter_kernel.cl";
  char *source = LoadProgramSourceFromFile(scatter_filename);
  if (!source) printf("Error loading '%s' source.\n", scatter_filename);

  HadopeTask scatter_task = buildTaskFromSource(
    env,
    source,
    strlen(source),
    "ScatterFilterKernel"
  );

  /* Ensure that retrieval has finished then use fetched data to set correct result dataset length */
  ret = clFinish(env.queue);
  if (ret != CL_SUCCESS) printf("clFinish %s\n", oclErrorString(ret));

  int filtered_entries = index_reduce + last_element_presence;
  cl_mem filtered_buffer = clCreateBuffer(
    env.context,
    CL_MEM_HOST_READ_ONLY,
    filtered_entries * sizeof(int),
    NULL,
    NULL
  );

  ret = clSetKernelArg(
    scatter_task.kernel,  // Kernel concerned
    0,                    // Index of argument to specify
    sizeof(cl_mem),       // Size of argument value
    &input_dataset.buffer // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  ret = clSetKernelArg(
    scatter_task.kernel,  // Kernel concerned
    1,                    // Index of argument to specify
    sizeof(cl_mem),       // Size of argument value
    &presence.buffer      // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  ret = clSetKernelArg(
    scatter_task.kernel,  // Kernel concerned
    2,                    // Index of argument to specify
    sizeof(cl_mem),       // Size of argument value
    &index_scan.buffer    // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  ret = clSetKernelArg(
    scatter_task.kernel,  // Kernel concerned
    3,                    // Index of argument to specify
    sizeof(cl_mem),       // Size of argument value
    &filtered_buffer      // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  size_t g_work_size[1] = {input_dataset.buffer_entries};
  /* Kernel enqueued to be executed on the environment's command queue */
  ret = clEnqueueNDRangeKernel(
    env.queue,           // Device's command queue
    scatter_task.kernel, // Kernel to enqueue
    1,                   // Dimensionality of work
    0,                   // Global offset of work index
    g_work_size,         // Array of work size in each dimension
    NULL,                // Local work size, omitted so will be deduced by OpenCL platform
    0,                   // Number of preceding events
    NULL,                // Preceding events list
    NULL                 // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueNDRangeKernel %s\n", oclErrorString(ret));

  clReleaseMemObject(input_dataset.buffer);

  filtered_dataset.buffer_entries = filtered_entries;
  filtered_dataset.buffer = filtered_buffer;
  return filtered_dataset;
}
/* ~~ END Task Dispatching Methods ~~ */

