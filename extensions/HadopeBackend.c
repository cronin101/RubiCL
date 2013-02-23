#include "ruby.h"
#include "./hadope.h"

HadopeEnvironment env;

static VALUE init_OpenCL_environment(cl_device_type device_type){
  HadopeEnvironment *environment;
  VALUE environment_object;

  environment = malloc(sizeof(HadopeEnvironment));
  *environment = createHadopeEnvironment(device_type);
  environment_object = Data_Wrap_Struct(environment_object, NULL, NULL, environment);
  return environment_object;
}

static VALUE method_init_GPU_environment(VALUE self){
  return init_OpenCL_environment(CL_DEVICE_TYPE_GPU);
}

static VALUE method_create_memory_buffer(VALUE self,  VALUE num_entries_object,
                                                      VALUE type_string_object){
  HadopeEnvironment *environment;
  HadopeMemoryBuffer *mem_struct;
  VALUE environment_object;
  VALUE memory_struct_object;
  char* type_string;
  int unit_size;
  int num_entries;

  type_string = StringValuePtr(type_string_object);
  if (!strcmp(type_string, "int")){
    unit_size = INT2FIX(sizeof(int));
  } else {
    rb_raise(rb_eTypeError, "Provided type not understood by size_of");
  }

  mem_struct = malloc(sizeof(HadopeMemoryBuffer));
  num_entries = FIX2INT(num_entries_object);
  mem_struct->buffer_entries = num_entries;
  environment_object = rb_ivar_get(self, (rb_intern("environment")));
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);
  mem_struct->buffer = createMemoryBuffer(*environment, num_entries * unit_size);
  memory_struct_object = Data_Wrap_Struct(memory_struct_object, NULL, NULL,
                                                               mem_struct);

  return memory_struct_object;
}

static VALUE method_load_int_dataset(VALUE self, VALUE dataset_object,
                                          VALUE memory_struct_object){
  int array_size;
  int i;
  int *dataset;
  HadopeMemoryBuffer *mem_struct;

  Check_Type(dataset_object, T_ARRAY);
  array_size = RARRAY_LEN(dataset_object);
  dataset = malloc(sizeof(int) * array_size);
  for (i=0; i < array_size; i++) {
    dataset[i] = FIX2INT(rb_ary_entry(dataset_object, i));
  }
  Data_Get_Struct(memory_struct_object, HadopeMemoryBuffer, mem_struct);
  loadIntArrayIntoDevice(env, *mem_struct, dataset);

  return self;
}

static VALUE method_retrieve_int_dataset(VALUE self, VALUE memory_struct_object){
  int array_size;
  int *dataset;
  int i;
  HadopeMemoryBuffer *mem_struct;
  VALUE output_array;

  Data_Get_Struct(memory_struct_object, HadopeMemoryBuffer, mem_struct);
  array_size = mem_struct->buffer_entries;
  dataset = malloc(array_size * sizeof(int));
  getIntArrayFromDevice(env, *mem_struct, dataset);
  output_array = rb_ary_new2(array_size);
  for (i = 0; i < array_size; i++){
    rb_ary_store(output_array, i, INT2FIX(dataset[i]));
  }

  return output_array;
}

static VALUE method_run_task(VALUE self, VALUE task_source_object, VALUE source_size_object,
                                            VALUE task_name_object, VALUE mem_struct_object){
  char* task_source;
  int source_size;
  char* task_name;
  HadopeTask task;
  HadopeMemoryBuffer *mem_struct;

  Data_Get_Struct(mem_struct_object, HadopeMemoryBuffer, mem_struct);
  task_source = StringValuePtr(task_source_object);
  source_size = FIX2INT(source_size_object);
  task_name = StringValuePtr(task_name_object);
  task = buildTaskFromSource(env, task_source, source_size, task_name);
  runTaskOnCurrentDataset(env, *mem_struct, task);

  return self;
}

static VALUE method_clean_used_resources(VALUE self, VALUE mem_struct_object){
  HadopeMemoryBuffer *mem_struct;
  Data_Get_Struct(mem_struct_object, HadopeMemoryBuffer, mem_struct);
  clFlush(env.queue);
  clFinish(env.queue);
  clReleaseMemObject(mem_struct->buffer);

  return self;
}

void Init_hadope_backend() {
  printf("HadopeBackend native code included.\n");
  VALUE HadopeBackend = rb_define_module("HadopeBackend");
  rb_define_method(HadopeBackend, "init_GPU_environment", method_init_GPU_environment, 0);
  rb_define_method(HadopeBackend, "create_memory_buffer", method_create_memory_buffer, 3);
  rb_define_method(HadopeBackend, "load_int_dataset", method_load_int_dataset, 2);
  rb_define_method(HadopeBackend, "retrieve_int_dataset", method_retrieve_int_dataset, 1);
  rb_define_method(HadopeBackend, "run_task", method_run_task, 4);
  rb_define_method(HadopeBackend, "clean_used_resources", method_clean_used_resources, 1);
}
