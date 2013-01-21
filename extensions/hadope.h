#include <stdio.h>
#include <stdlib.h>
#ifdef __APPLE__
  #include <OpenCL/opencl.h>
#else
  #include <CL/cl.h>
#endif
#include "oclerrorexplain.h"

typedef struct {
  cl_device_id device_id;
  cl_context context;
  cl_command_queue queue;
} HadopeEnvironment;

typedef struct {
  cl_kernel kernel;
  cl_program program;
  char* name;
} HadopeTask;

typedef struct{
  int buffer_size;
  cl_mem buffer;
} HadopeMemoryBuffer;

HadopeEnvironment createHadopeEnvironment();

cl_mem createMemoryBuffer(const HadopeEnvironment env, const int required_memory);

HadopeTask buildTaskFromSource(const HadopeEnvironment env, const char* kernel_source,
                                                const size_t source_size, char* name);

void loadIntArrayIntoDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                                        const int *dataset);

void getIntArrayFromDevice(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                                              int *dataset);

void runTaskOnCurrentDataset(const HadopeEnvironment env, const HadopeMemoryBuffer mem_struct,
                                                                       const HadopeTask task);
