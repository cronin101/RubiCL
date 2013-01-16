#include <stdio.h>
#include <stdlib.h>
#include <CL/cl.h>

#define MEM_SIZE (128)
#define MAX_SOURCE_SIZE (0x100000)

void readKernelSource(const char* filename, char* *source_string, int *size);

void createContextWithQueueAndBuffer(cl_context *context, cl_command_queue *queue, cl_mem *memory_buffer);
