#ifndef HADOPE_H
#define HADOPE_H
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifdef __APPLE__
  #include <OpenCL/opencl.h>
#else
  #include <CL/cl.h>
#endif

clock_t getTime(char* description);

typedef struct {
    clock_t pipeline_start;
    clock_t pipeline_total;
    clock_t memory_start;
    clock_t memory_total;
    clock_t computation_start;
    clock_t computation_total;
} RubiCLTimings;

typedef struct {
    cl_device_id device_id;
    cl_context context;
    cl_command_queue queue;
    RubiCLTimings timings;
} RubiCLEnvironment;

typedef struct {
    cl_device_id cpu_device_id;
    cl_device_id gpu_device_id;
    cl_context context;
    cl_command_queue cpu_queue;
    cl_command_queue gpu_queue;
    RubiCLTimings timings;
} RubiCLHybridEnvironment;

typedef struct {
    cl_kernel kernel;
    cl_program program;
    char* name;
} RubiCLTask;

typedef enum {
    INTEGER_BUFFER,
    DOUBLE_BUFFER
} buffer_contents_type;

typedef struct {
    int buffer_entries;
    cl_mem buffer;
    buffer_contents_type type;
} RubiCLMemoryBuffer;

void createRubiCLEnvironment(
    const cl_device_type device_type,
    RubiCLEnvironment* env
);

void createRubiCLHybridEnvironment(
    RubiCLHybridEnvironment* env
);

cl_mem createMemoryBuffer(
    const RubiCLEnvironment* env,
    const size_t required_memory,
    const cl_mem_flags type
);

void pinArrayForDevice(
    const cl_context* context,
    void* dataset,
    int dataset_length,
    size_t dataset_size,
    RubiCLMemoryBuffer* result,
    buffer_contents_type type
);

void buildTaskFromSource(
    const RubiCLEnvironment* env,
    const char* kernel_source,
    const char* name,
    RubiCLTask* result
);

void loadIntArrayIntoDevice(
    const RubiCLEnvironment env,
    const RubiCLMemoryBuffer mem_struct,
    int *dataset
);

void getIntArrayFromDevice(
    const RubiCLEnvironment env,
    const RubiCLMemoryBuffer mem_struct,
    int *dataset
);

void* getPinnedArrayFromDevice(
    cl_command_queue* queue,
    const RubiCLMemoryBuffer* mem_struct,
    const size_t unit_size,
    RubiCLTimings* bm
);

void runTaskOnDataset(
    const RubiCLEnvironment* env,
    const RubiCLMemoryBuffer* mem_struct,
    const RubiCLTask* task
);

void computePresenceArrayForDataset(
    const RubiCLEnvironment* env,
    const RubiCLMemoryBuffer* mem_struct,
    const RubiCLTask* task,
  RubiCLMemoryBuffer* presence
);

void computePresenceArrayForTupDataset(
    const RubiCLEnvironment* env,
    const RubiCLMemoryBuffer* fst_mem_struct,
    const RubiCLMemoryBuffer* snd_mem_struct,
    const RubiCLTask* task,
  RubiCLMemoryBuffer* presence
);

void exclusivePrefixSum(
    const RubiCLEnvironment* env,
    const RubiCLMemoryBuffer* presence,
    char* source,
    RubiCLMemoryBuffer* result
);

void integerBitonicSort(
    const RubiCLEnvironment* env,
    RubiCLMemoryBuffer* input_dataset,
    RubiCLTask* task
);

int sumIntegerDataset(
    const RubiCLEnvironment* env,
    RubiCLMemoryBuffer* input_dataset,
    char* source
);

void runTaskOnTupDataset(
    const RubiCLEnvironment* env,
    const RubiCLTask* task,
    RubiCLMemoryBuffer* fsts,
    RubiCLMemoryBuffer* snds
);

int filteredBufferLength(
    const RubiCLEnvironment* env,
    RubiCLMemoryBuffer* presence,
    RubiCLMemoryBuffer* input_dataset
);

void filterByScatteredWrites(
    const RubiCLEnvironment* env,
    RubiCLMemoryBuffer* input_dataset,
    RubiCLMemoryBuffer* presence,
    RubiCLMemoryBuffer* index_scan
);

void releaseTemporaryFilterBuffers(
    RubiCLMemoryBuffer* presence,
    RubiCLMemoryBuffer* index_scan
);

void releaseDeviceDataset(
    RubiCLMemoryBuffer* dataset
);
#endif
