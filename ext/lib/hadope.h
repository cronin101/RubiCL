#ifndef HADOPE_H
#define HADOPE_H
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
  int buffer_entries;
  cl_mem buffer;
} HadopeMemoryBuffer;

HadopeEnvironment createHadopeEnvironment(const cl_device_type device_type);

cl_mem createMemoryBuffer(
  const HadopeEnvironment env,
  const size_t required_memory,
  const cl_mem_flags type
);

HadopeTask buildTaskFromSource(
  const HadopeEnvironment env,
  const char* kernel_source,
  const size_t source_size, char* name
);

void loadIntArrayIntoDevice(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  int *dataset
);

void getIntArrayFromDevice(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  int *dataset
);
void runTaskOnDataset(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  const HadopeTask task
);

void computePresenceArrayForDataset(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  const HadopeTask task,
  HadopeMemoryBuffer * presence
);

void filterDatasetByPresence(
  const HadopeEnvironment env,
  const HadopeMemoryBuffer mem_struct,
  const HadopeMemoryBuffer presence
);
#endif
