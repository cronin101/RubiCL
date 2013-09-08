#include "ruby.h"
#include "lib/hadope.h"

/* ~~ Init Methods ~~ */

/* Finds an OpenCL device of the given type and creates a HadopeEnvironment
 * struct that records its device_id and newly created context/command queue
 *
 * @device_type: CL_DEVICE_TYPE_GPU / CL_DEVICE_TYPE_CPU */
static VALUE initOpenCLenvironment(cl_device_type device_type){
  VALUE environment_object = rb_define_class("HadopeEnvironment", rb_cObject);

  HadopeEnvironment* environment = malloc(sizeof(HadopeEnvironment));
  *environment = createHadopeEnvironment(device_type);

  /* Struct is turned into a Ruby object so that it can be stored as an ivar */
  return Data_Wrap_Struct(environment_object, NULL, &free, environment);
}

/* Following two methods do what they say on the tin. */
static VALUE methodInitGPUEnvironment(VALUE self){
  return initOpenCLenvironment(CL_DEVICE_TYPE_GPU);
}

static VALUE methodInitCPUEnvironment(VALUE self){
  return initOpenCLenvironment(CL_DEVICE_TYPE_CPU);
}

/* ~~ END Init Methods ~~ */

/* ~~ Device Memory Management Methods ~~ */

/* Creates a memory buffer capable of storing N entries of a given type.
 *
 * @num_entries_object: Ruby object containing the array size as an integer.
 * @type_string_object: Ruby object containing the C type of the entries as a string. */
static VALUE methodCreateMemoryBuffer(
  VALUE self,
  VALUE num_entries_object,
  VALUE type_string_object
){
  VALUE environment_object;
  int unit_size;

  VALUE memory_struct_object = rb_define_class("HadopeMemoryBuffer", rb_cObject);

  /* Pulling string out of Ruby object and strcmp to set unit size of array
   * FIXME Make this less hacky, it feels bad.*/
  char* type_string = StringValuePtr(type_string_object);
  if (!strcmp(type_string, "int")){
    unit_size = INT2FIX(sizeof(int));
  } else {
    rb_raise(rb_eTypeError, "Provided type not understood by size_of");
  }

  HadopeMemoryBuffer* mem_struct = malloc(sizeof(HadopeMemoryBuffer));
  mem_struct->buffer_entries = FIX2INT(num_entries_object);

  environment_object = rb_iv_get(self, "@environment");
  HadopeEnvironment* environment;
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);

  /* Memory buffer is created and then wrapped in a Ruby object stored by device class */
  mem_struct->buffer = createMemoryBuffer(
    *environment,
    mem_struct->buffer_entries * unit_size,
    CL_MEM_READ_WRITE
  );

  return Data_Wrap_Struct(memory_struct_object, NULL, &free, mem_struct);
}

/* Loads an integer array from given Ruby object into the cl_mem buffer previously created
 *
 * @dataset_object: Ruby object containing an array of integers.
 * @memory_struct_object: Ruby object storing previously created HadopeMemoryBuffer. */
static VALUE methodLoadIntDataset(
  VALUE self,
  VALUE dataset_object,
  VALUE memory_struct_object
){
  int i;
  HadopeMemoryBuffer *mem_struct;
  HadopeEnvironment *environment;

  Check_Type(dataset_object, T_ARRAY);

  /* Iteration over Ruby integer array converting Ruby FIXNUMs to C ints. */
  int array_size = RARRAY_LEN(dataset_object);
  int* dataset = calloc(array_size, sizeof(int));
  for (i=0; i < array_size; i++) dataset[i] = FIX2INT(rb_ary_entry(dataset_object, i));

  Data_Get_Struct(memory_struct_object, HadopeMemoryBuffer, mem_struct);
  VALUE environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);

  /* Enqueue the task to load converted dataset into ocl device buffer. */
  loadIntArrayIntoDevice(*environment, *mem_struct, dataset);

  return self;
}

/* Loads a (processed?) integer array from the ocl device and converts it
 * into a Ruby array to be returned to the device class
 *
 * @memory_struct_object: Ruby object storing HadopeMemoryBuffer. */
static VALUE methodRetrieveIntDataset(VALUE self, VALUE memory_struct_object){
  int i;
  HadopeMemoryBuffer *mem_struct;
  HadopeEnvironment *environment;

  /* Create recipient array large enough to store entries in buffer */
  Data_Get_Struct(memory_struct_object, HadopeMemoryBuffer, mem_struct);
  int* dataset = calloc(mem_struct->buffer_entries, sizeof(int));

  VALUE environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);

  /* Enqueue the task to read array from OCL device into recipient */
  getIntArrayFromDevice(*environment, *mem_struct, dataset);

  /* Create new Ruby array and fill with C ints converted to FIXNUMs */
  VALUE output_array = rb_ary_new2(mem_struct->buffer_entries);
  for (i = 0; i < mem_struct->buffer_entries; i++) rb_ary_store(output_array, i, INT2FIX(dataset[i]));
  free(dataset);

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
static VALUE methodRunMapTask(
  VALUE self,
  VALUE task_source_object,
  VALUE source_size_object,
  VALUE task_name_object,
  VALUE mem_struct_object
){
  HadopeMemoryBuffer *mem_struct;
  HadopeEnvironment *environment;

  /* Convert Objects into C types and builds Kernel using environment ivar */
  char* task_source = StringValuePtr(task_source_object);
  int source_size = FIX2INT(source_size_object);
  char* task_name = StringValuePtr(task_name_object);
  VALUE environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);
  HadopeTask task = buildTaskFromSource(*environment, task_source, source_size, task_name);

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
static VALUE methodRunFilterTask(
  VALUE self,
  VALUE task_source_object,
  VALUE source_size_object,
  VALUE task_name_object,
  VALUE mem_struct_object
){
  HadopeMemoryBuffer *dataset;
  HadopeEnvironment *environment;
  int i;

  /* Convert Objects into C types and builds Kernel using environment ivar */
  char* task_source = StringValuePtr(task_source_object);
  int source_size = FIX2INT(source_size_object);
  char* task_name = StringValuePtr(task_name_object);
  VALUE environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);
  HadopeTask task = buildTaskFromSource(*environment, task_source, source_size, task_name);

  /* Enqueues the task to run on the dataset specified by the HadopeMemoryBuffer */
  Data_Get_Struct(mem_struct_object, HadopeMemoryBuffer, dataset);
  HadopeMemoryBuffer* presence = malloc(sizeof(HadopeMemoryBuffer));
  computePresenceArrayForDataset(*environment, *dataset, task, presence);
  HadopeMemoryBuffer prescan = exclusivePrefixSum(*environment, *presence);

  int* result = calloc(prescan.buffer_entries, sizeof(int));
  getIntArrayFromDevice(*environment, prescan, result);

  *dataset = filterByScatteredWrites(*environment, *dataset, *presence, prescan);

  releaseTemporaryFilterBuffers(presence, &prescan);
  return self;
}

/* ~~ END Task Dispatching Methods ~~ */

static VALUE methodCleanUsedResources(VALUE self, VALUE mem_struct_object){
  HadopeMemoryBuffer *dataset;
  HadopeEnvironment *environment;

  Data_Get_Struct(mem_struct_object, HadopeMemoryBuffer, dataset);
  VALUE environment_object = rb_iv_get(self, "@environment");
  Data_Get_Struct(environment_object, HadopeEnvironment, environment);
  clFlush(environment->queue);
  clFinish(environment->queue);
  clReleaseMemObject(dataset->buffer);

  return self;
}

/* Used to give extension methods defined above to device class when HadopeBackend module is included. */
void Init_hadope_backend(){
  VALUE HadopeBackend = rb_define_module("HadopeBackend");
  rb_define_private_method(HadopeBackend, "init_GPU_environment", methodInitGPUEnvironment, 0);
  rb_define_private_method(HadopeBackend, "initialize_CPU_environment", methodInitCPUEnvironment, 0);
  rb_define_private_method(HadopeBackend, "create_memory_buffer", methodCreateMemoryBuffer, 2);
  rb_define_private_method(HadopeBackend, "transfer_integer_dataset_to_buffer", methodLoadIntDataset, 2);
  rb_define_private_method(HadopeBackend, "retrieve_integer_dataset_from_buffer", methodRetrieveIntDataset, 1);
  rb_define_private_method(HadopeBackend, "run_map_task", methodRunMapTask, 4);
  rb_define_private_method(HadopeBackend, "run_filter_task", methodRunFilterTask, 4);
  rb_define_private_method(HadopeBackend, "clean_used_resources", methodCleanUsedResources, 1);
}
