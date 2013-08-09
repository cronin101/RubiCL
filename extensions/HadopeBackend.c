#include "ruby.h"
#include "./hadope.h"

/* ~~ Init Methods ~~ */

/* Finds an OpenCL device of the given type and creates a HadopeEnvironment
 * struct that records its device_id and newly created context/command queue
 *
 * @device_type: CL_DEVICE_TYPE_GPU / CL_DEVICE_TYPE_CPU */
static VALUE
init_OpenCL_environment(cl_device_type device_type){
  HadopeEnvironment *environment;
  VALUE environment_object;
  environment_object = rb_define_class("HadopeEnvironment", rb_cObject);

  environment = malloc(sizeof(HadopeEnvironment));
  *environment = createHadopeEnvironment(device_type);

  /* Struct is turned into a Ruby object so that it can be stored as an ivar */
  environment_object = Data_Wrap_Struct(environment_object, NULL, NULL, environment);

  return environment_object;
}

/* Following two methods do what they say on the tin. */
static VALUE
method_init_GPU_environment(VALUE self){
  return init_OpenCL_environment(CL_DEVICE_TYPE_GPU);
}

static VALUE
method_init_CPU_environment(VALUE self){
  return init_OpenCL_environment(CL_DEVICE_TYPE_CPU);
}

/* ~~ END Init Methods ~~ */

/* ~~ Device Memory Management Methods ~~ */

/* Creates a memory buffer capable of storing N entries of a given type.
 *
 * @num_entries_object: Ruby object containing the array size as an integer.
 * @type_string_object: Ruby object containing the C type of the entries as a string. */
static VALUE
method_create_memory_buffer(VALUE self, VALUE num_entries_object, VALUE type_string_object){
  HadopeEnvironment *environment;
  HadopeMemoryBuffer *mem_struct;
  VALUE environment_object;
  VALUE memory_struct_object;
  char* type_string;
  int unit_size;
  int num_entries;

  memory_struct_object = rb_define_class("HadopeMemoryBuffer", rb_cObject);

  /* Pulling string out of Ruby object and strcmp to set unit size of array
   * FIXME Make this less hacky, it feels bad.*/
  type_string = StringValuePtr(type_string_object);
  if (!strcmp(type_string, "int")){
    unit_size = INT2FIX(sizeof(int));
  } else {
    rb_raise(rb_eTypeError, "Provided type not understood by size_of");
  }

  mem_struct = malloc(sizeof(HadopeMemoryBuffer));
  num_entries = FIX2INT(num_entries_object);
  mem_struct->buffer_entries = num_entries;
  environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);

  /* Memory buffer is created and then wrapped in a Ruby object stored by device class */
  mem_struct->buffer = createMemoryBuffer(     *environment         ,
                                            num_entries * unit_size ,
                                              CL_MEM_READ_WRITE    );
  memory_struct_object = Data_Wrap_Struct(memory_struct_object, NULL, NULL,
                                                               mem_struct);

  return memory_struct_object;
}

/* Loads an integer array from given Ruby object into the cl_mem buffer previously created
 *
 * @dataset_object: Ruby object containing an array of integers.
 * @memory_struct_object: Ruby object storing previously created HadopeMemoryBuffer. */
static VALUE
method_load_int_dataset(VALUE self, VALUE dataset_object, VALUE memory_struct_object){
  int array_size;
  int i;
  int *dataset;
  HadopeMemoryBuffer *mem_struct;
  HadopeEnvironment *environment;
  VALUE environment_object;

  Check_Type(dataset_object, T_ARRAY);

  /* Iteration over Ruby integer array converting Ruby FIXNUMs to C ints. */
  array_size = RARRAY_LEN(dataset_object);
  dataset = malloc(sizeof(int) * array_size);
  for (i=0; i < array_size; i++) {
    dataset[i] = FIX2INT(rb_ary_entry(dataset_object, i));
  }

  Data_Get_Struct(memory_struct_object, HadopeMemoryBuffer, mem_struct);
  environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);

  /* Enqueue the task to load converted dataset into ocl device buffer. */
  loadIntArrayIntoDevice(*environment, *mem_struct, dataset);

  return self;
}

/* Loads a (processed?) integer array from the ocl device and converts it
 * into a Ruby array to be returned to the device class
 *
 * @memory_struct_object: Ruby object storing HadopeMemoryBuffer. */
static VALUE
method_retrieve_int_dataset(VALUE self, VALUE memory_struct_object){
  int array_size;
  int *dataset;
  int i;
  HadopeMemoryBuffer *mem_struct;
  VALUE output_array;
  HadopeEnvironment *environment;
  VALUE environment_object;

  /* Create recipient array large enough to store entries in buffer */
  Data_Get_Struct(memory_struct_object, HadopeMemoryBuffer, mem_struct);
  array_size = mem_struct->buffer_entries;
  dataset = malloc(array_size * sizeof(int));

  environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);

  /* Enqueue the task to read array from olc device into recipient */
  getIntArrayFromDevice(*environment, *mem_struct, dataset);

  /* Create new Ruby array and fill with C ints converted to FIXNUMs */
  output_array = rb_ary_new2(array_size);
  for (i = 0; i < array_size; i++){
    rb_ary_store(output_array, i, INT2FIX(dataset[i]));
  }

  return output_array;
}

/* ~~ END Memory Management Methods ~~ */

/* ~~ Task Dispatching Methods ~~ */

/* Takes a code-generated OpenCL kernel and builds it for the target ocl device
 * then enqueues its execution on a specified dataset.
 *
 * @task_source_object: Ruby object storing the kernel as a String.
 * @source_size_object: Ruby object specifying the size of the kernel String.
 * @task_name_object: Ruby object specifying the task within the source to enqueue.
 * @memory_struct_object: Ruby object containing HadopeMemoryBuffer to process. */
static VALUE
method_run_map_task(VALUE self, VALUE task_source_object, VALUE source_size_object,
                                VALUE task_name_object, VALUE mem_struct_object){
  char* task_source;
  int source_size;
  char* task_name;
  HadopeTask task;
  HadopeMemoryBuffer *mem_struct;
  HadopeEnvironment *environment;
  VALUE environment_object;

  /* Convert Objects into C types and builds Kernel using environment ivar */
  task_source = StringValuePtr(task_source_object);
  source_size = FIX2INT(source_size_object);
  task_name = StringValuePtr(task_name_object);
  environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);
  task = buildTaskFromSource(*environment, task_source, source_size, task_name);

  /* Enqueues the task to run on the dataset specified by the HadopeMemoryBuffer */
  Data_Get_Struct(mem_struct_object, HadopeMemoryBuffer, mem_struct);
  runTaskOnDataset(*environment, *mem_struct, task);

  return self;
}

/* Takes a code-generated Filter kernel and builds it for device then executes on dataset.
 * FIXME: Refactor pasted code from above method that is present here.
 *
 * @task_source_object: Ruby object storing the kernel as a String.
 * @source_size_object: Ruby object specifying the size of the kernel String.
 * @task_name_object: Ruby object specifying the task within the source to enqueue.
 * @memory_struct_object: Ruby object containing HadopeMemoryBuffer to process. */
static VALUE
method_run_filter_task(VALUE self, VALUE task_source_object, VALUE source_size_object,
                                     VALUE task_name_object, VALUE mem_struct_object){
  char* task_source;
  int source_size;
  char* task_name;
  HadopeTask task;
  HadopeMemoryBuffer *mem_struct;
  HadopeMemoryBuffer *presence_struct;
  VALUE presence_object;
  HadopeEnvironment *environment;
  VALUE environment_object;

  /* Convert Objects into C types and builds Kernel using environment ivar */
  task_source = StringValuePtr(task_source_object);
  source_size = FIX2INT(source_size_object);
  task_name = StringValuePtr(task_name_object);
  environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);
  task = buildTaskFromSource(*environment, task_source, source_size, task_name);

  /* Enqueues the task to run on the dataset specified by the HadopeMemoryBuffer */
  Data_Get_Struct(mem_struct_object, HadopeMemoryBuffer, mem_struct);
  presence_struct = malloc(sizeof(HadopeMemoryBuffer));
  computePresenceArrayForDataset(*environment, *mem_struct, task, presence_struct);

  /* DIRTY_HACK: Packages presence_strut to be returned to device class */
  presence_object = rb_define_class("HadopePresenceArray", rb_cObject);
  presence_object = Data_Wrap_Struct(presence_object, NULL, NULL, presence_struct);
  return presence_object;
}

/* ~~ END Task Dispatching Methods ~~ */

static VALUE
method_clean_used_resources(VALUE self, VALUE mem_struct_object){
  HadopeMemoryBuffer *mem_struct;
  HadopeEnvironment *environment;
  VALUE environment_object;

  Data_Get_Struct(mem_struct_object, HadopeMemoryBuffer, mem_struct);
  environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);
  clFlush(environment->queue);
  clFinish(environment->queue);
  clReleaseMemObject(mem_struct->buffer);

  return self;
}

/* Used to give extension methods defined above to device class when HadopeBackend module is included. */
void
Init_hadope_backend(){
  VALUE HadopeBackend = rb_define_module("HadopeBackend");
  rb_define_private_method(HadopeBackend, "init_GPU_environment", method_init_GPU_environment, 0);
  rb_define_private_method(HadopeBackend, "init_CPU_environment", method_init_CPU_environment, 0);
  rb_define_private_method(HadopeBackend, "create_memory_buffer", method_create_memory_buffer, 2);
  rb_define_private_method(HadopeBackend, "load_int_dataset", method_load_int_dataset, 2);
  rb_define_private_method(HadopeBackend, "retrieve_int_dataset", method_retrieve_int_dataset, 1);
  rb_define_private_method(HadopeBackend, "run_map_task", method_run_map_task, 4);
  rb_define_private_method(HadopeBackend, "run_filter_task", method_run_filter_task, 4);
  rb_define_private_method(HadopeBackend, "clean_used_resources", method_clean_used_resources, 1);
}
