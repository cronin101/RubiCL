#include "/Users/aaron/.rvm/src/ruby-1.9.3-p327-perf/include/ruby.h"

static VALUE method_derp(VALUE self) {
  printf("oh god how did I get here what is going on\n");
  return self;
}

void Init_hadopebackend() {
  printf("wat\n");
  VALUE HadopeBackend = rb_define_module("HadopeBackend");
  rb_define_method(HadopeBackend, "derp", method_derp, 0);
}
