#include "ruby.h"
#include "./hadope.h"

cl_mem memory_buffer;
HadopeEnvironment env;

static VALUE method_derp(VALUE self){
  printf("oh god how did I get here what is going on\n");
  return self;
}

static VALUE method_size_of(VALUE self, VALUE type_string_object){
  char* type_string;

  type_string = StringValuePtr(type_string_object);
  if (!strcmp(type_string, "int")){
    return INT2FIX(sizeof(int));
  } else {
    rb_raise(rb_eTypeError, "Provided type not understood by size_of");
    return INT2FIX(0);
  }
}

static VALUE method_init_OpenCL_environment(VALUE self){
  env = createHadopeEnvironment();
  printf("OpenCL environment initialised.\n");

  return self;
}

static VALUE method_create_memory_buffer(VALUE self, VALUE required_memory_object){
  memory_buffer = createMemoryBuffer(env, FIX2INT(required_memory_object));

  return self;
}

static VALUE method_load_int_dataset(VALUE self, VALUE dataset_object){
  int array_size;
  int i;
  int *dataset;

  Check_Type(dataset_object, T_ARRAY);
  array_size = RARRAY_LEN(dataset_object);
  dataset = malloc(sizeof(int) * array_size);
  for (i=0; i < array_size; i++) {
    dataset[i] = FIX2INT(rb_ary_entry(dataset_object, i));
  }

  return self;
}

static VALUE method_run_task(VALUE self, VALUE task_source_object, VALUE source_size_object, VALUE task_name_object){
  char* task_source;
  int source_size;
  char* task_name;
  HadopeTask task;

  task_source = StringValuePtr(task_source_object);
  source_size = FIX2INT(source_size_object);
  task_name = StringValuePtr(task_name_object);
  task = buildTaskFromSource(env, task_source, source_size, task_name);

  return self;
}

void Init_hadope_backend() {
  printf("HadopeBackend native code included.\n");
  VALUE HadopeBackend = rb_define_module("HadopeBackend");
  rb_define_method(HadopeBackend, "init_OpenCL_environment", method_init_OpenCL_environment, 0);
  rb_define_method(HadopeBackend, "create_memory_buffer", method_create_memory_buffer, 1);
  rb_define_method(HadopeBackend, "load_int_dataset", method_load_int_dataset, 1);
  rb_define_method(HadopeBackend, "run_task", method_run_task, 3);
  rb_define_method(HadopeBackend, "size_of", method_size_of, 1);
  rb_define_method(HadopeBackend, "derp", method_derp, 0);
}
