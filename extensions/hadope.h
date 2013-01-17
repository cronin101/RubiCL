#include <stdio.h>
#include <stdlib.h>
#include <CL/cl.h>

#define MEM_SIZE (128)
#define MAX_SOURCE_SIZE (0x100000)

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

HadopeEnvironment createHadopeEnvironment();

cl_mem createMemoryBuffer(const HadopeEnvironment env, const int required_memory);

HadopeTask buildTaskFromSource(const HadopeEnvironment env, const char* kernel_source, const size_t source_size, char* name);
