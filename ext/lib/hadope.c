#include "./hadope.h"
#include "prefix_sum/prescan.h"
#include "oclerrorexplain.h"

#define DEBUG 0

void releaseMemoryCallback(
    cl_event event,
    cl_int event_command_exec_status,
    void* memory
) {
    if (DEBUG) printf("releaseMemoryCallback\n");
    free(memory);
}

void setGroupSize(
  const HadopeEnvironment* env
) {
    if (DEBUG) printf("setGroupSize\n");
    size_t max_workgroup_size = 0;
    size_t returned_size = 0;
    cl_int ret = clGetDeviceInfo(
        env->device_id,
        CL_DEVICE_MAX_WORK_GROUP_SIZE,
        sizeof(size_t),
        &max_workgroup_size,
        &returned_size
    );

    if (ret != CL_SUCCESS) printf("clGetDeviceInfo %s\n", oclErrorString(ret));
    GROUP_SIZE = min(GROUP_SIZE,  max_workgroup_size);
}

void displayDeviceInfo(cl_uint num_devices, cl_device_id* devices) {
    if (DEBUG) printf("displayDeviceInfo\n");

    char buf[128];
    size_t max_workgroup_size;
    for (cl_uint i = 0; i < num_devices; ++i) {
        clGetDeviceInfo(devices[i], CL_DEVICE_VENDOR, 128, buf, NULL);
        printf("* Device %d: %s ", (i + 1), buf);
        clGetDeviceInfo(devices[i], CL_DEVICE_NAME, 128, buf, NULL);
        printf("%s\n", buf);
        clGetDeviceInfo(devices[i], CL_DEVICE_VERSION, 128, buf, NULL);
        printf("\tSupports: %s\n", buf);
        clGetDeviceInfo(devices[i], CL_DEVICE_MAX_WORK_GROUP_SIZE, 128, &max_workgroup_size, NULL);
        printf("\tMax workgroup size: %lu\n", max_workgroup_size);
    }
}

void displayBuildFailureInfo(cl_program program, cl_device_id device_id) {
        // Determine the size of the log
        size_t log_size;
        clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);

        // Allocate memory for the log
        char *log = (char *) malloc(log_size);

        // Get the log
        clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, log_size, log, NULL);

        // Print the log
        printf("%s\n", log);
        free(log);
}

cl_platform_id selectDefaultClPlatform() {
    if (DEBUG) printf("selectDefaultClPlatform\n");
    cl_platform_id platform;
    cl_int ret;

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

    return platform;
}

cl_device_id selectDefaultClDeviceOfType(cl_device_type device_type, cl_platform_id* platform) {
    if (DEBUG) printf("selectDefaultClDeviceOfType\n");

    cl_int ret;
    cl_device_id device_id;
    cl_uint num_devices;

    ret = clGetDeviceIDs(
        *platform,    // Selected platform
        device_type, // Type of device (CPU/GPU)
        0,           // Limit
        NULL,        // Devices destination
        &num_devices // Count destination
    );

    cl_device_id* devices = calloc(sizeof(cl_device_id), num_devices);
    ret = clGetDeviceIDs(
        *platform,    // Selected platform
        device_type, // Type of device (CPU/GPU)
        num_devices, // Limit
        devices,     // Devices destination
        NULL         // Count destination
    );
    if (ret != CL_SUCCESS) printf("clGetDeviceIDs %s\n", oclErrorString(ret));

    if (DEBUG) {
        displayDeviceInfo(num_devices, devices);
        printf("Selecting Device 1.\n");
    }
    device_id = devices[0];
    free(devices);

    return device_id;
}

/* ~~ Init Methods ~~ */

/* Selects target device then creates context and command queue, packages in HadopeEnvironment and returns.
 *
 * @device_type: CL_DEVICE_TYPE_GPU / CL_DEVICE_TYPE_CPU */
void createHadopeEnvironment(const cl_device_type device_type, HadopeEnvironment* env) {
    if (DEBUG) printf("createHadopeEnvironment\n");

    cl_int ret;

    /* Selecting an OpenCL platform */
    cl_platform_id platform = selectDefaultClPlatform();

    /* Selecting a device */
    env->device_id = selectDefaultClDeviceOfType(device_type, &platform);

    /* Create OpenCL context for target device and store in environment*/
    env->context = clCreateContext(
        NULL,           // Context properties to set
        1,              // Number of devices specified
        &env->device_id,// Device specified
        NULL,           // Error callback function
        NULL,           // User data specified
        &ret            // Status destination
    );
    if (ret != CL_SUCCESS) printf("clCreateContext %s\n", oclErrorString(ret));

    /* Create command queue for context/target-device and store in environment */
    env->queue = clCreateCommandQueue(
        env->context,   // Context to use
        env->device_id, // Device to send commands to
        0,              // Queue properties bitfield, neither out_of_order nor profiling flags set.
        &ret            // Status destination
    );
    if (ret != CL_SUCCESS) printf("clCreateCommandQueue %s\n", oclErrorString(ret));

    /* Record the maximum supported group size. */
    setGroupSize(env);
}

void createHadopeHybridEnvironment(HadopeHybridEnvironment* env) {
    if (DEBUG) printf("createHadopeHybridEnvironment\n");

    cl_int ret;

    cl_platform_id platform = selectDefaultClPlatform();

    env->cpu_device_id = selectDefaultClDeviceOfType(CL_DEVICE_TYPE_CPU, &platform);
    env->gpu_device_id = selectDefaultClDeviceOfType(CL_DEVICE_TYPE_GPU, &platform);

    cl_device_id devices[2] = { env->cpu_device_id, env->gpu_device_id };

    env->context = clCreateContext(
        NULL,           // Properties
        2,              // Number of devices specified
        devices,        // Devices specified
        NULL,           // Error callback Fn
        NULL,           // User data for Fn
        &ret            // Status destination
    );
    if (ret != CL_SUCCESS) printf("clCreateContext %s\n", oclErrorString(ret));

    env->cpu_queue = clCreateCommandQueue(
        env->context,
        env->cpu_device_id,
        0,
        &ret
    );
    if (ret != CL_SUCCESS) printf("clCreateCommandQueue (CPU) %s\n", oclErrorString(ret));


    env->gpu_queue = clCreateCommandQueue(
        env->context,
        env->gpu_device_id,
        0,
        &ret
    );
    if (ret != CL_SUCCESS) printf("clCreateCommandQueue (GPU) %s\n", oclErrorString(ret));

    //FIXME: Set GroupSize or something.
}

/* ~~ END Init Methods ~~ */

/* Device Memory Management Methods ~~ */

/* Creates a cl_mem buffer with a given memory capacity and given access flags.
 *
 * @env: Struct containing device/context/queue variables.
 * @req_memory: The size of the memory buffer to create.
 * @fs: Flags to set on memory buffer... CL_MEM_READ_WRITE/CL_MEM_READ. */
cl_mem createMemoryBuffer(
  const HadopeEnvironment* env,
  const size_t req_memory,
  const cl_mem_flags flags
) {
    if (DEBUG) printf("createMemoryBuffer\n");
  cl_int ret;
  cl_mem buffer = clCreateBuffer(
    env->context, // Context to use
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
    if (DEBUG) printf("loadIntArrayIntoDevice\n");
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

/* Pins an existing dataset into device-addressable memory
 *
 * @env: Struct containing device/context/queue variables.
 * @dataset: Pointer to an integer array of data to be pinned
 * @length: Length of the integer dataset being pinned.
 *
 * @Return: cl_mem reference for addressing pinned memory. */
void pinArrayForDevice(
    const cl_context* context,
    void* dataset,
    int dataset_length,
    size_t dataset_size,
    HadopeMemoryBuffer* result,
    buffer_contents_type type
) {

    if (DEBUG) printf("pinArrayForDevice\n");
    cl_int ret;
    result->type = type;
    result->buffer_entries = dataset_length;
    result->buffer = clCreateBuffer(
        *context,                                   // Context to use
        CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR,    // cl_mem_flags set
        dataset_size,                               // Size of buffer
        dataset,                                    // Dataset to pin
        &ret                                        // Status destination
    );
    if (ret != CL_SUCCESS) printf("clCreateBuffer %s\n", oclErrorString(ret));
}

/* Reads the contents of device memory buffer into a given dataset array
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing cl_mem buffer and the number of entries it can hold.
 * @dataset: Pointer to an integer array of data to be written, same length as buffer */
void getIntArrayFromDevice(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  int* dataset
) {
    if (DEBUG) printf("getIntArrayFromDevice\n");
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

/* Reads the contents of a pinned dataset via DMA request
 *
 *  @env: Struct containing device/context/queue variables.*
 *  @mem_struct Struct containing cl_mem buffer referencing dataset. */
void* getPinnedArrayFromDevice(
    cl_command_queue* queue,
    const HadopeMemoryBuffer* mem_struct,
    const size_t unit_size
){
    if (DEBUG) printf("getPinnedArrayFromDevice\n");
    /* Wait for pending actions */
    clFinish(*queue);

    cl_int ret;
    return clEnqueueMapBuffer(
        *queue,
        mem_struct->buffer,
        CL_TRUE,
        CL_MAP_READ,
        0,
        mem_struct->buffer_entries * unit_size,
        0,
        NULL,
        NULL,
        &ret
    );
}

void releaseTemporaryFilterBuffers(
  HadopeMemoryBuffer* presence,
  HadopeMemoryBuffer* index_scan
) {
    if (DEBUG) printf("releaseTemporaryFilterBuffers\n");
  clReleaseMemObject(presence->buffer);
  clReleaseMemObject(index_scan->buffer);
}

void releaseDeviceDataset(
  HadopeMemoryBuffer* dataset
) {
    if (DEBUG) printf("releaseDeviceDataset\n");
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
void buildTaskFromSource(
  const HadopeEnvironment* env,
  const char* kernel_source,
  const char* name,
  HadopeTask* result
) {
    if (DEBUG) printf("buildTaskFromSource\n");

  /* Create cl_program from given task/name and store inside HadopeTask struct. */
  cl_int ret;
  result->name = (char *) name;
  result->program = clCreateProgramWithSource(
    env->context,                    // Context
    1,                              // Number of parts that the source is in
    (const char **) &kernel_source, // Array of program source code
    NULL,                           // Total size of source
    &ret                            // Status destination
  );
  if (ret != CL_SUCCESS) printf("clCreateProgramWithSource %s\n", oclErrorString(ret));

  /* Create kernel from cl_program to execute later on target-device */
  ret = clBuildProgram(
    result->program,            // Program to build
    1,                       // Number of devices involved
    &env->device_id,          // List of involved devices
    "-cl-fast-relaxed-math", // Compilation options
    NULL,                    // Build complete callback, building is synchronous if omitted
    NULL                     // Callback user data
  );
  if (ret != CL_SUCCESS) printf("clBuildProgram %s\n", oclErrorString(ret));

    if (ret == CL_BUILD_PROGRAM_FAILURE) displayBuildFailureInfo(result->program, env->device_id);

  result->kernel = clCreateKernel(
    result->program, // Built program
    result->name,    // Entry point to kernel
    &ret          // Status destination
  );
  if (ret != CL_SUCCESS) printf("clCreateKernel %s\n", oclErrorString(ret));
}

/* ~~ END Task Compilation Methods ~~ */

/* ~~ Task Dispatching Methods ~~ */

/* Enqueues a given task to operate on a given memory buffer dataset.
 *
 * @env: Struct containing device/context/queue variables.
 * @mem_struct: Struct containing cl_mem buffer / target dataset.
 * @task: Struct containing the kernel to execute and the task name. */
void runTaskOnDataset(
  const HadopeEnvironment* env,
  const HadopeMemoryBuffer* mem_struct,
  const HadopeTask* task
) {
    if (DEBUG) printf("runTaskOnDataset\n");
  size_t g_work_size[1] = {mem_struct->buffer_entries};

  /* Kernel's global data_array set to be the given device memory buffer */
  cl_int ret = clSetKernelArg(
    task->kernel,       // Kernel concerned
    0,                 // Index of argument to specify
    sizeof(cl_mem),    // Size of argument value
    &mem_struct->buffer // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  /* Kernel enqueued to be executed on the environment's command queue */
  ret = clEnqueueNDRangeKernel(
    env->queue,   // Device's command queue
    task->kernel, // Kernel to enqueue
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
  const HadopeEnvironment* env,
  const HadopeMemoryBuffer* mem_struct,
  const HadopeTask* task,
  HadopeMemoryBuffer *presence
) {
    if (DEBUG) printf("computePresenceArrayForDataset\n");
  size_t g_work_size[1] = {mem_struct->buffer_entries};

  /* Kernel's global data_array set to be the given device memory buffer */
  cl_int ret = clSetKernelArg(
    task->kernel,       // Kernel concerned
    0,                 // Index of argument to specify
    sizeof(cl_mem),    // Size of argument value
    &mem_struct->buffer // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  /* Output buffer created to be an int flag for each element in input dataset. */
  presence->buffer_entries = mem_struct->buffer_entries;
  presence->buffer = createMemoryBuffer(
    env,                                      // Environment struct
    (presence->buffer_entries * sizeof(int)), // Size of buffer to create
    CL_MEM_HOST_READ_ONLY                     // Buffer flags set
  );
  presence->type = INTEGER_BUFFER;

  /* Kernel's global presence_array set to be the newly created presence buffer */
  ret = clSetKernelArg(
    task->kernel,      // Kernel concerned
    1,                // Index of argument to specify
    sizeof(cl_mem),   // Size of argument value
    &presence->buffer // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg PA %s\n", oclErrorString(ret));

  /* Kernel enqueued to be executed on the environment's command queue */
  ret = clEnqueueNDRangeKernel(
    env->queue,   // Device's command queue
    task->kernel, // Kernel to enqueue
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

void exclusivePrefixSum(
  const HadopeEnvironment* env,
  const HadopeMemoryBuffer* input,
  char* source,
  HadopeMemoryBuffer* result
) {
    if (DEBUG) printf("exclusivePrefixSum\n");

  cl_int ret;

    size_t unit_size;
    switch (input->type) {
    case (INTEGER_BUFFER):
        unit_size = sizeof(int);
        break;
    case (DOUBLE_BUFFER):
        unit_size = sizeof(double);
        break;
    }

  result->buffer = clCreateBuffer(
    env->context,
    CL_MEM_HOST_READ_ONLY,
    input->buffer_entries * unit_size,
    NULL,
    NULL
  );

  ComputeProgram = clCreateProgramWithSource(
    env->context,
    1,
    (const char **) &source,
    NULL,
    &ret
  );
  if (ret != CL_SUCCESS) printf("clCreateProgramWithSource %s\n", oclErrorString(ret));

  ret = clBuildProgram(
    ComputeProgram,
    1,                       // Number of devices involved
    &env->device_id,          // List of involved devices
    "-cl-fast-relaxed-math", // Compilation options
    NULL,                    // Build complete callback, building is synchronous if omitted
    NULL                     // Callback user data
  );
  if (ret != CL_SUCCESS) printf("clBuildProgram %s\n", oclErrorString(ret));
    if (ret == CL_BUILD_PROGRAM_FAILURE) displayBuildFailureInfo(ComputeProgram, env->device_id);

  ComputeKernels = (cl_kernel*) calloc(KernelCount, sizeof(cl_kernel));

  for(int i = 0; i < KernelCount; ++i) {
    ComputeKernels[i] = clCreateKernel(
      ComputeProgram,
      KernelNames[i],
      &ret
    );
    if (!ComputeKernels[i] || ret != CL_SUCCESS) printf("clCreateKernel %s\n", oclErrorString(ret));

    size_t wgSize;
    ret = clGetKernelWorkGroupInfo(
      ComputeKernels[i],
      env->device_id,
      CL_KERNEL_WORK_GROUP_SIZE,
      sizeof(size_t),
      &wgSize,
      NULL
    );
    if (ret != CL_SUCCESS) printf("clGetKernelWorkGroupInfo %s\n", oclErrorString(ret));
    GROUP_SIZE = min(GROUP_SIZE, wgSize);
  }

  CreatePartialSumBuffers(input->buffer_entries, env->context, unit_size);
  PreScanBuffer(env->queue, result->buffer, input->buffer, GROUP_SIZE, GROUP_SIZE, input->buffer_entries, unit_size);

  ret = clFinish(env->queue);
  if (ret != CL_SUCCESS) printf("clFinish %s\n", oclErrorString(ret));

  ReleasePartialSums();
  for(int k = 0; k < KernelCount; ++k) clReleaseKernel(ComputeKernels[k]);
  clReleaseProgram(ComputeProgram);

  result->buffer_entries = input->buffer_entries;
}

void integerBitonicSort(
    const HadopeEnvironment* env,
    HadopeMemoryBuffer* input_dataset,
    HadopeTask* task
) {
    /* num_stages = log_2(buffer_entries) */
    unsigned int temp = input_dataset->buffer_entries, num_stages = 0;
    while (temp >>= 1) ++num_stages;

    /* Dataset argument */
    cl_int ret = clSetKernelArg(
        task->kernel,          // Kernel concerned
        0,                     // Index of argument to specify
        sizeof(cl_mem),        // Size of argument value
        &input_dataset->buffer // Argument value
    );

    /* Dataset length argument */
    ret = clSetKernelArg(
        task->kernel,                       // Kernel concerned
        3,                                  // Index of argument to specify
        sizeof(cl_uint),                    // Size of argument value
        &input_dataset->buffer_entries      // Argument value
    );

    /* Sort order argument */
    int ascending_sort = 1;
    cl_uint sort_order = ascending_sort ? 1 : 0;
    ret = clSetKernelArg(
        task->kernel,          // Kernel concerned
        4,                     // Index of argument to specify
        sizeof(cl_uint),       // Size of argument value
        &sort_order            // Argument value
    );

    for (unsigned int stage = 0; stage < num_stages; ++stage) {
        /* Inform kernel of current stage. */
        ret = clSetKernelArg(
            task->kernel,          // Kernel concerned
            1,                     // Index of argument to specify
            sizeof(cl_uint),       // Size of argument value
            &stage                 // Argument value
        );

        /* Each stage n : N involves (n + 1) passes. */
        for (unsigned int pass = 0; pass < stage + 1; ++pass) {
            /* Inform kernel of current pass. */
            ret = clSetKernelArg(
                task->kernel,          // Kernel concerned
                2,                     // Index of argument to specify
                sizeof(cl_uint),       // Size of argument value
                &pass                  // Argument value
            );

            /* Perform pass. */
            size_t g_work_size[1] = {input_dataset->buffer_entries / 2};
            ret = clEnqueueNDRangeKernel(
                env->queue,     // Device's command queue
                task->kernel,   // Kernel to enqueue
                1,              // Dimensionality of work
                0,              // Global offset of work index
                g_work_size,    // Array of work size in each dimension
                NULL,           // Local work size, omitted so will be deduced by OpenCL platform
                0,              // Number of preceding events
                NULL,           // Preceding events list
                NULL            // Event object destination
            );
        }
    }
}
/* Returns the summation of a integer dataset.
 *
 * @env: Struct containing device/context/queue variables.
 * @input_dataset: Struct containing cl_mem buffer / target dataset. */
int sumIntegerDataset(
    const HadopeEnvironment* env,
    HadopeMemoryBuffer* input_dataset,
    char* source
) {
    if (DEBUG) printf("sumIntegerDataset\n");

    HadopeMemoryBuffer prefixed;
    exclusivePrefixSum(env, input_dataset, source, &prefixed);

    /* Sum is last element of input dataset added to last element of
     * exclusive prefix summed dataset */
    int input_last, prefix_last;
    /* Reading the last element of the _exclusive_ prefix sum */
    cl_int ret = clEnqueueReadBuffer(
        env->queue,                                      // Command queue
        prefixed.buffer,                                // Buffer holding exc prefix sum
        CL_FALSE,                                       // Async to hide latency
        (prefixed.buffer_entries - 1) * sizeof(int),    // Final element offset
        sizeof(int),                                    // Output size
        &prefix_last,                                   // Output destination
        0, NULL,                                        // Num, List preceding actions
        NULL                                            // Event object destination
    );

    /* Reading the last element of the input dataset */
    input_last = * (int *) clEnqueueMapBuffer(
        env->queue,                                          // Command queue
        input_dataset->buffer,                               // Buffer holding input dataset
        CL_FALSE,                                           // Async to hide latency
        CL_MAP_READ,
        (input_dataset->buffer_entries - 1) * sizeof(int),   // Final element offset
        sizeof(int),                                        // Output size
        0, NULL,                                            // Num, List preceding actions
        NULL,                                               // Event object destination
        &ret
    );

    /* Ensure that reading has finished */
    ret = clFinish(env->queue);

    clReleaseMemObject(input_dataset->buffer);
    clReleaseMemObject(prefixed.buffer);

    return input_last + prefix_last;
}

/* Returns the number of elements that would be kept after a presence array calculation
 * has been completed.
 *
 * @env: HadopeEnvironment struct
 * @presence: presence array post filter calculation.
 * @index_scan: result of exclusive prefix sum on presence array. */
int filteredBufferLength(
    const HadopeEnvironment* env,
    HadopeMemoryBuffer* presence,
    HadopeMemoryBuffer* index_scan
) {
    if (DEBUG) printf("filteredBufferLength\n");

  int index_reduce, last_element_presence;
  cl_int ret = clEnqueueReadBuffer(
    env->queue,                                     // Device's command queue
    index_scan->buffer,                             // Buffer to output data from
    CL_FALSE,                                      // Block? Async to hide latency
    (index_scan->buffer_entries - 1) * sizeof(int), // Offset to read from
    sizeof(int),                                   // Size of output data
    &index_reduce,                                 // Output destination
    0,                                             // Number of preceding actions
    NULL,                                          // List of preceding actions
    NULL                                           // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));

  ret = clEnqueueReadBuffer(
    env->queue,                                   // Device's command queue
    presence->buffer,                             // Buffer to output data from
    CL_FALSE,                                    // Block? Async to hide latency
    (presence->buffer_entries - 1) * sizeof(int), // Offset to read from
    sizeof(int),                                 // Size of output data
    &last_element_presence,                      // Output destination
    0,                                           // Number of preceding actions
    NULL,                                        // List of preceding actions
    NULL                                         // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));

  clFinish(env->queue);

  return index_reduce + last_element_presence;
}

void filterByScatteredWrites(
  const HadopeEnvironment* env,
  HadopeMemoryBuffer* input_dataset,
  HadopeMemoryBuffer* presence,
  HadopeMemoryBuffer* index_scan
) {
    if (DEBUG) printf("filterByScatteredWrites\n");

  HadopeMemoryBuffer filtered_dataset;
  int index_reduce, last_element_presence;
  cl_int ret = clEnqueueReadBuffer(
    env->queue,                                     // Device's command queue
    index_scan->buffer,                             // Buffer to output data from
    CL_FALSE,                                      // Block? Async to hide latency
    (index_scan->buffer_entries - 1) * sizeof(int), // Offset to read from
    sizeof(int),                                   // Size of output data
    &index_reduce,                                 // Output destination
    0,                                             // Number of preceding actions
    NULL,                                          // List of preceding actions
    NULL                                           // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));

  ret = clEnqueueReadBuffer(
    env->queue,                                   // Device's command queue
    presence->buffer,                             // Buffer to output data from
    CL_FALSE,                                    // Block? Async to hide latency
    (presence->buffer_entries - 1) * sizeof(int), // Offset to read from
    sizeof(int),                                 // Size of output data
    &last_element_presence,                      // Output destination
    0,                                           // Number of preceding actions
    NULL,                                        // List of preceding actions
    NULL                                         // Event object destination
  );
  if (ret != CL_SUCCESS) printf("clEnqueueReadBuffer %s\n", oclErrorString(ret));

  /* Build kernel whilst data is being fetched from device */
    const char* scatter_filename;
    const char* scatter_taskname;
    switch (input_dataset->type) {
    case (INTEGER_BUFFER):
        scatter_filename = "./ext/lib/integer_scatter_kernel.cl";
        scatter_taskname = "IntegerScatterFilterKernel";
        break;
    case (DOUBLE_BUFFER):
        scatter_filename = "./ext/lib/double_scatter_kernel.cl";
        scatter_taskname = "DoubleScatterFilterKernel";
        break;
    }
  char *source = LoadProgramSourceFromFile(scatter_filename);
  if (!source) printf("Error loading '%s' source.\n", scatter_filename);

  HadopeTask scatter_task;
  buildTaskFromSource(
    env,
    source,
    scatter_taskname,
    &scatter_task
  );

  /* Ensure that retrieval has finished then use fetched data to set correct result dataset length */
  ret = clFinish(env->queue);
  if (ret != CL_SUCCESS) printf("clFinish %s\n", oclErrorString(ret));

    int filtered_entries = index_reduce + last_element_presence;
    size_t filtered_buffer_size;
    switch (input_dataset->type) {
    case (INTEGER_BUFFER):
        filtered_buffer_size = filtered_entries * sizeof(int);
        break;
    case (DOUBLE_BUFFER):
        filtered_buffer_size = filtered_entries * sizeof(double);
        break;
    }
  cl_mem filtered_buffer = clCreateBuffer(
    env->context,
    CL_MEM_HOST_READ_ONLY,
    filtered_buffer_size,
    NULL,
    NULL
  );

  ret = clSetKernelArg(
    scatter_task.kernel,   // Kernel concerned
    0,                     // Index of argument to specify
    sizeof(cl_mem),        // Size of argument value
    &input_dataset->buffer // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  ret = clSetKernelArg(
    scatter_task.kernel,  // Kernel concerned
    1,                    // Index of argument to specify
    sizeof(cl_mem),       // Size of argument value
    &presence->buffer      // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  ret = clSetKernelArg(
    scatter_task.kernel,  // Kernel concerned
    2,                    // Index of argument to specify
    sizeof(cl_mem),       // Size of argument value
    &index_scan->buffer    // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  ret = clSetKernelArg(
    scatter_task.kernel,  // Kernel concerned
    3,                    // Index of argument to specify
    sizeof(cl_mem),       // Size of argument value
    &filtered_buffer      // Argument value
  );
  if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

  size_t g_work_size[1] = {input_dataset->buffer_entries};
  /* Kernel enqueued to be executed on the environment's command queue */
  ret = clEnqueueNDRangeKernel(
    env->queue,           // Device's command queue
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

  clReleaseMemObject(input_dataset->buffer);

  filtered_dataset.buffer_entries = filtered_entries;
  filtered_dataset.buffer = filtered_buffer;

  *input_dataset = filtered_dataset;
}

void braidBuffers(
    const HadopeEnvironment* env,
    const HadopeTask* task,
    HadopeMemoryBuffer* fsts,
    HadopeMemoryBuffer* snds
) {
    if (DEBUG) printf("braidBuffers\n");

    cl_int ret = clSetKernelArg(
        task->kernel,   // Kernel concerned
        0,              // Index of argument to specify
        sizeof(cl_mem), // Size of argument value
        &fsts->buffer   // Argument pointer
    );
    if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

    ret = clSetKernelArg(
        task->kernel,   // Kernel concerned
        1,              // Index of argument to specify
        sizeof(cl_mem), // Size of argument value
        &snds->buffer   // Argument pointer
    );
    if (ret != CL_SUCCESS) printf("clSetKernelArg %s\n", oclErrorString(ret));

    /* Kernel enqueued to be executed on the environment's command queue */
    size_t g_work_size[1] = {fsts->buffer_entries};
    ret = clEnqueueNDRangeKernel(
        env->queue,   // Device's command queue
        task->kernel, // Kernel to enqueue
        1,            // Dimensionality of work
        0,            // Global offset of work index
        g_work_size,  // Array of work sizes by dimension
        NULL,         // Local work size, omitted so will be automatically deduced
        0,            // Number of preceding events
        NULL,         // Preceding events list
        NULL          // Event object destination
    );
    if (ret != CL_SUCCESS) printf("clEnqueueNDRangeKernel %s\n", oclErrorString(ret));
}
/* ~~ END Task Dispatching Methods ~~ */

