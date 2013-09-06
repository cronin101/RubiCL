#ifndef OCLERROREXPLAIN_H
#define OCLERROREXPLAIN_H
#ifdef __APPLE__
  #include <OpenCL/opencl.h>
#else
  #include <CL/cl.h>
#endif

const char* oclErrorString(cl_int error);
#endif
