#include "ruby.h"
#include "./hadope.h"

cl_context context;
cl_command_queue queue;
cl_mem memory_buffer;


static VALUE method_derp(VALUE self) {
  printf("oh god how did I get here what is going on\n");
  return self;
}

static VALUE method_init_OpenCL_environment(VALUE self) {
  createContextWithQueueAndBuffer(&context, &queue, &memory_buffer);
  printf("OpenCL environment initialised.\n");
  return self;
}

void Init_hadope_backend() {
  printf("HadopeBackend native code included.\n");
  VALUE HadopeBackend = rb_define_module("HadopeBackend");
  rb_define_method(HadopeBackend, "init_OpenCL_environment", method_init_OpenCL_environment, 0);
  rb_define_method(HadopeBackend, "derp", method_derp, 0);
}
