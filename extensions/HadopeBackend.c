#include "ruby.h"

static VALUE method_derp(VALUE self) {
  printf("oh god how did I get here what is going on\n");
  return self;
}

void Init_hadope_backend() {
  printf("HadopeBackend native code included.\n");
  VALUE HadopeBackend = rb_define_module("HadopeBackend");
  rb_define_method(HadopeBackend, "derp", method_derp, 0);
}
