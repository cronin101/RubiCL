#include "hadope.h"

void readKernelSource(const char* filename, char* *source_string, int *size){
  FILE *fp;

  if ( !(fp = fopen( filename, "r" )) ){
    fprintf(stderr, "Failed to load Kernel source.\n");
    exit(1);
  } else {
    *source_string = (char*) malloc( MAX_SOURCE_SIZE );
    *size = fread(*source_string, 1, MAX_SOURCE_SIZE, fp);
    fclose(fp);
   }
}

void createContextWithQueue(cl_context *context, cl_command_queue *queue){
  cl_platform_id platform_id = NULL;
  cl_device_id device_id = NULL;
  cl_uint ret_num_platforms;
  cl_uint ret_num_devices;
  cl_int ret;

  ret = clGetPlatformIDs(1, &platform_id, &ret_num_platforms);
  ret = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_DEFAULT,
                        1, &device_id, &ret_num_devices);
  *context = clCreateContext(NULL, 1, &device_id, NULL, NULL, &ret);
  *queue = clCreateCommandQueue(*context, device_id, 0, &ret);
}

void createMemoryBuffer(cl_context *context, cl_command_queue *queue, cl_mem *memory_buffer, int required_memory){
  cl_int ret;
  *memory_buffer = clCreateBuffer(*context, CL_MEM_READ_WRITE, required_memory, NULL, &ret);
}
