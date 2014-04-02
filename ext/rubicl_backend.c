#include <limits.h>

#include "ruby.h"
#include "lib/rubicl.h"

/* ~~ BEGIN Helpers ~~ */
RubiCLEnvironment* environmentPtrFromIvar(VALUE self) {
    RubiCLEnvironment* environment;
    VALUE environment_object = rb_iv_get(self, "@environment");
    Data_Get_Struct(environment_object, RubiCLEnvironment, environment);
    return environment;
}

RubiCLMemoryBuffer* mem_structPtrFromObj(VALUE mem_struct_object) {
    RubiCLMemoryBuffer* mem_struct;
    Data_Get_Struct(mem_struct_object, RubiCLMemoryBuffer, mem_struct);
    return mem_struct;
}

VALUE environmentObjFromPtr(RubiCLEnvironment* environment) {
    VALUE environment_object = rb_define_class("RubiCLEnvironment", rb_cObject);
    return Data_Wrap_Struct(environment_object, NULL, &free, environment);
}

VALUE mem_struct_objectFromPtr(RubiCLMemoryBuffer* mem_struct) {
    VALUE mem_struct_object = rb_define_class("RubiCLMemoryBuffer", rb_cObject);
    return Data_Wrap_Struct(mem_struct_object, NULL, &free, mem_struct);
}

VALUE methodBufferLength(VALUE self, VALUE mem_struct_object) {
    return(INT2FIX(mem_structPtrFromObj(mem_struct_object)->buffer_entries));
}

VALUE methodLastMemoryDuration(VALUE self) {
    RubiCLEnvironment* env = environmentPtrFromIvar(self);
    return DBL2NUM((float) env->timings.memory_total * 1000 / CLOCKS_PER_SEC);
}

VALUE methodLastComputationDuration(VALUE self) {
    RubiCLEnvironment* env = environmentPtrFromIvar(self);
    return DBL2NUM((float) env->timings.computation_total * 1000 / CLOCKS_PER_SEC);
}

VALUE methodLastPipelineDuration(VALUE self) {
    RubiCLEnvironment* env = environmentPtrFromIvar(self);
    return DBL2NUM(((float) env->timings.pipeline_total * 1000 / CLOCKS_PER_SEC));
}


/* ~~ END Helpers ~~ */

/* ~~ Init Methods ~~ */

/* Finds an OpenCL device of the given type and creates a RubiCLEnvironment
 * struct that records its device_id and newly created context/command queue
 *
 * @device_type: CL_DEVICE_TYPE_GPU / CL_DEVICE_TYPE_CPU */
static VALUE initOpenCLenvironment(cl_device_type device_type) {
    RubiCLEnvironment* environment = malloc(sizeof(RubiCLEnvironment));
    createRubiCLEnvironment(device_type, environment);
    return environmentObjFromPtr(environment);
}

/* Following two methods do what they say on the tin. */
static VALUE methodInitGPUEnvironment(VALUE self) {
    return initOpenCLenvironment(CL_DEVICE_TYPE_GPU);
}

static VALUE methodInitCPUEnvironment(VALUE self) {
    return initOpenCLenvironment(CL_DEVICE_TYPE_CPU);
}

static VALUE methodInitHybridEnvironment(VALUE self) {
    RubiCLHybridEnvironment* environment;
    environment = malloc(sizeof(*environment));
    createRubiCLHybridEnvironment(environment);
    VALUE hybrid_environment_object = rb_define_class("RubiCLHybridEnvironment", rb_cObject);
    return Data_Wrap_Struct(hybrid_environment_object, NULL, &free, environment);
}

/* ~~ END Init Methods ~~ */

/* ~~ Device Memory Management Methods ~~ */

/* Creates a memory buffer capable of storing N entries of a given type.
 *
 * @num_entries_object: Ruby object containing the array size as an integer.
 * @type_string_object: Ruby object containing the C type of the entries as a string. */
static VALUE /* ### THIS METHOD IS DEPRECATED ### */ methodCreateMemoryBuffer(VALUE self, VALUE num_entries_object, VALUE type_string_object) {
    //rb_warn("create_memory_buffer is deprecated, use create_pinned_x_buffer instead");
    int unit_size;

    /* Pulling string out of Ruby object and strcmp to set unit size of array
    * FIXME Make this less hacky, it feels bad.*/
    char* type_string = StringValuePtr(type_string_object);
    RubiCLMemoryBuffer* mem_struct = malloc(sizeof(RubiCLMemoryBuffer));

    if (!strcmp(type_string, "int")){
        unit_size = INT2FIX(sizeof(int));
        mem_struct->type = INTEGER_BUFFER;
    } else {
        free(mem_struct);
        rb_raise(rb_eTypeError, "Provided type not understood by size_of");
    }

    mem_struct->buffer_entries = FIX2INT(num_entries_object);

    RubiCLEnvironment* environment = environmentPtrFromIvar(self);

    /* Memory buffer is created and then wrapped in a Ruby object stored by device class */
    mem_struct->buffer = createMemoryBuffer(environment, mem_struct->buffer_entries * unit_size,
                                            CL_MEM_READ_WRITE);

    return mem_struct_objectFromPtr(mem_struct);
}

/* Creates a memory buffer object containing a device-accessible reference to a subset of the given FIXNNUM dataset.
 *
 * @dataset_object: The Ruby object containing an array of integers.
 * @start: The index of the first element in the slice (FIXNUM).
 * @finish: The index of the last element in the slice (FIXNUM). */
static VALUE methodPinIntRange(cl_context* context, VALUE dataset_object, VALUE start, VALUE finish) {
    Check_Type(dataset_object, T_ARRAY);
    int start_i = FIX2INT(start);
    int finish_i = FIX2INT(finish);
    int array_length = (finish_i - start_i) + 1;
    size_t array_size = array_length * sizeof(int);
    int* dataset = malloc(array_size);
    for (int i = 0; i < array_length; ++i) dataset[i] = rb_ary_entry(dataset_object, start_i + i);

    RubiCLMemoryBuffer* mem_struct = malloc(sizeof(RubiCLMemoryBuffer));
    pinArrayForDevice(context, dataset, array_length, array_size, mem_struct, INTEGER_BUFFER);

    return mem_struct_objectFromPtr(mem_struct);
}

/*  Creates a memory buffer object containing a device-accessible reference to the given FIXNUM dataset.
 *
 *  @dataset_object: Ruby object containing an array of integers. */
static VALUE methodPinIntDataset(VALUE self, VALUE dataset_object) {
    cl_context* context;
    RubiCLTimings* bm;

    float start_time = getTime("Started Pinning");

    // FIXME?: This is far too magic.
    int is_hybrid = RTEST(rb_funcall(self, rb_intern("is_hybrid?"), 0));
    if (is_hybrid) {
        RubiCLHybridEnvironment* environment;
        VALUE environment_object = rb_iv_get(self, "@environment");
        Data_Get_Struct(environment_object, RubiCLHybridEnvironment, environment);
        context = &environment->context;
        bm = &environment->timings;
    } else {
        RubiCLEnvironment* environment = environmentPtrFromIvar(self);
        context = &((RubiCLEnvironment*)environment)->context;
        bm = &environment->timings;
    }

    VALUE pinned_buffer =  methodPinIntRange(context, dataset_object, INT2FIX(0), INT2FIX(RARRAY_LEN(dataset_object) - 1));

    float finish_time = getTime("Finished Pinning");

    bm->memory_total = finish_time - start_time;
    bm->pipeline_start = start_time;

    return pinned_buffer;
}

static VALUE methodPinIntFile(VALUE self, VALUE filename_object) {
    char* filename = StringValuePtr(filename_object);
    FILE* fp;

    int ary_length = 16, ints_read = 0, num;
    int* dataset = malloc(ary_length * sizeof(int));
    if (!(fp = fopen(filename, "r"))) rb_raise(rb_eIOError, "PinIntFile: File access error.");

    while (fscanf(fp, "%d\n", &num) == 1) {
        if (++ints_read > ary_length) dataset = realloc(dataset, (ary_length *= 2) * sizeof(int));
        dataset[ints_read - 1] = INT2FIX(num);
    }
    dataset = realloc(dataset, ints_read * sizeof(int));

    RubiCLEnvironment* environment = environmentPtrFromIvar(self);

    RubiCLMemoryBuffer* mem_struct = malloc(sizeof(RubiCLMemoryBuffer));
    pinArrayForDevice(&environment->context, dataset, ints_read, ints_read * sizeof(int),
                        mem_struct, INTEGER_BUFFER);
    return mem_struct_objectFromPtr(mem_struct);
}

/*  Creates a memory buffer object containing a device-accessible reference to the given FLOAT dataset.
 *
 *  @dataset_object: Ruby object containing an array of doubles. */
static VALUE methodPinDoubleDataset(VALUE self, VALUE dataset_object) {
    Check_Type(dataset_object, T_ARRAY);
    int array_length = RARRAY_LEN(dataset_object);
    size_t array_size = array_length * sizeof(double);
    double* dataset = malloc(array_size);

    for (int i = 0; i < array_length; ++i) dataset[i] = NUM2DBL(rb_ary_entry(dataset_object, i));

    RubiCLEnvironment* environment = environmentPtrFromIvar(self);

    RubiCLMemoryBuffer* mem_struct = malloc(sizeof(RubiCLMemoryBuffer));
    pinArrayForDevice(&environment->context, dataset, array_length, array_size, mem_struct, DOUBLE_BUFFER);
    return mem_struct_objectFromPtr(mem_struct);
}

/* Loads an integer array from given Ruby object into the cl_mem buffer previously created
 *
 * @dataset_object: Ruby object containing an array of integers.
 * @memory_struct_object: Ruby object storing previously created RubiCLMemoryBuffer. */
static VALUE methodLoadIntDataset(VALUE self, VALUE dataset_object, VALUE memory_struct_object) {
    Check_Type(dataset_object, T_ARRAY);

    RubiCLMemoryBuffer *mem_struct;
    Data_Get_Struct(memory_struct_object, RubiCLMemoryBuffer, mem_struct);

    RubiCLEnvironment* environment = environmentPtrFromIvar(self);

    /* Iteration over Ruby integer array converting Ruby FIXNUMs to C ints. */
    int array_size = RARRAY_LEN(dataset_object);
    int* dataset = calloc(array_size, sizeof(int));
    for (int i = 0; i < array_size; ++i) dataset[i] = rb_ary_entry(dataset_object, i);

    /* Enqueue the task to load converted dataset into ocl device buffer. */
    loadIntArrayIntoDevice(*environment, *mem_struct, dataset);
    mem_struct->type = INTEGER_BUFFER;
    return self;
}

/* Loads a (processed?) integer array from the ocl device and converts it
 * into a Ruby array to be returned to the device class
 *
 * @memory_struct_object: Ruby object storing RubiCLMemoryBuffer. */
static VALUE methodRetrieveIntDataset(VALUE self, VALUE memory_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(memory_struct_object);

    /* Create recipient array large enough to store entries in buffer */
    int* dataset = calloc(mem_struct->buffer_entries, sizeof(int));
    /* Enqueue the task to read array from OCL device into recipient */
    getIntArrayFromDevice(*environment, *mem_struct, dataset);
    /* Create new Ruby array and fill with C ints converted to FIXNUMs */
    VALUE output_array = rb_ary_new2(mem_struct->buffer_entries);
    for (int i = 0; i < mem_struct->buffer_entries; ++i) rb_ary_store(output_array, i, dataset[i]);

    releaseDeviceDataset(mem_struct);
    free(dataset);

    return output_array;
}

/* Loads a (processed?) integer array previously pinned for the ocl device and
 * converts it into a Ruby array to be returned to the device class.
 *
 * @memory_struct_object: Ruby object storing RubiCLMemoryBuffer. */
static VALUE methodRetrievePinnedIntDataset(VALUE self, VALUE memory_struct_object) {
    RubiCLTimings* bm;
    cl_command_queue* queue;


    /* The magic is back with a vengeance. */
    int is_hybrid = RTEST(rb_funcall(self, rb_intern("is_hybrid?"), 0));
    if (is_hybrid) {
        RubiCLHybridEnvironment* environment;
        VALUE environment_object = rb_iv_get(self, "@environment");
        Data_Get_Struct(environment_object, RubiCLHybridEnvironment, environment);
        queue = &environment->cpu_queue;
        bm = &environment->timings;
    } else {
        RubiCLEnvironment* environment = environmentPtrFromIvar(self);
        queue = &environment->queue;
        bm = &environment->timings;
    }

    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(memory_struct_object);

    int* dataset = getPinnedArrayFromDevice(queue, mem_struct, sizeof(int), bm);

    int entries = mem_struct->buffer_entries;
    VALUE output_array = rb_ary_new2(entries);

    for (int i = 0; i < entries; ++i) rb_ary_store(output_array, i, dataset[i]);
    releaseDeviceDataset(mem_struct);

    bm->memory_total = getTime("Finished Retrieving") - bm->memory_start;

    int finish_pipeline = getTime("Pipeline Complete");
    bm->pipeline_total = finish_pipeline - bm->pipeline_start;

    return output_array;
}

/* Loads a (processed?) double array previously pinned for the ocl device and
 * converts it into a Ruby array to be returned to the device class.
 *
 * @memory_struct_object: Ruby object storing RubiCLMemoryBuffer. */
static VALUE methodRetrievePinnedDoubleDataset(VALUE self, VALUE memory_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(memory_struct_object);
    RubiCLTimings* bm = &environment->timings;

    double* dataset = getPinnedArrayFromDevice(&environment->queue, mem_struct, sizeof(double), bm);

    int entries = mem_struct->buffer_entries;
    VALUE output_array = rb_ary_new2(entries);
    for (int i = 0; i < entries; ++i) rb_ary_store(output_array, i, DBL2NUM(dataset[i]));

    releaseDeviceDataset(mem_struct);

    return output_array;
}

/* ~~ END Memory Management Methods ~~ */

/* ~~ Task Dispatching Methods ~~ */

/* Returns the summation (fold with +) of a integer memory buffer.
 *
 * @memory_struct_object: Ruby object storing RubiCLMemoryBuffer. */
static VALUE methodSumIntegerBuffer(VALUE self, VALUE scan_task_source_object, VALUE memory_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(memory_struct_object);

    return INT2FIX(sumIntegerDataset(environment, mem_struct, StringValuePtr(scan_task_source_object)));
}

/* Takes a code-generated OpenCL kernel and builds it for the target ocl device
 * then enqueues its execution on a specified dataset.
 *
 * @task_source_object: Ruby object storing the kernel as a String.
 * @task_name_object: Ruby object specifying the task within the source to enqueue.
 * @memory_struct_object: Ruby object containing RubiCLMemoryBuffer to process. */
static VALUE methodRunMapTask(VALUE self, VALUE task_source_object, VALUE task_name_object, VALUE mem_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(mem_struct_object);
    environment->timings.computation_start = getTime("Map Enqueue Started");

    /* Early termination for empty buffer */
    environment->timings.computation_total = 0;
    if (!mem_struct->buffer_entries) return self;

    /* Convert Objects into C types and builds Kernel using environment ivar */
    RubiCLTask task;
    char* task_source = StringValuePtr(task_source_object);
    char* task_name = StringValuePtr(task_name_object);
    buildTaskFromSource(environment, task_source, task_name, &task);

    /* Enqueues the task to run on the dataset specified by the RubiCLMemoryBuffer */
    runTaskOnDataset(environment, mem_struct, &task);
    environment->timings.computation_total = getTime("Map Enqueue Finished") - environment->timings.computation_start;


    return self;
}

static VALUE methodRunHybridMapTask(VALUE self, VALUE task_source_object, VALUE task_name_object, VALUE memory_struct_object, VALUE cpu_slice_length_object, VALUE gpu_slice_length_object) {
    RubiCLHybridEnvironment* environment;
    VALUE environment_object = rb_iv_get(self, "@environment");
    Data_Get_Struct(environment_object, RubiCLHybridEnvironment, environment);

    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(memory_struct_object);
    /* Early termination for empty buffer */
    if (!mem_struct->buffer_entries) return self;

    /* Dummy env for each individual device */
    RubiCLEnvironment cpu_env = { environment->cpu_device_id, environment->context, environment->cpu_queue };
    RubiCLEnvironment gpu_env = { environment->gpu_device_id, environment->context, environment->gpu_queue };

    /* FIXME: Building the task twice is stupid... Maybe. */
    RubiCLTask cpu_task, gpu_task;
    char* task_source = StringValuePtr(task_source_object);
    char* task_name = StringValuePtr(task_name_object);
    buildTaskFromSource(&cpu_env, task_source, task_name, &cpu_task);
    buildTaskFromSource(&gpu_env, task_source, task_name, &gpu_task);

    /* Create proportional sub-buffers and run tasks */
    int cpu_slice_length = FIX2INT(cpu_slice_length_object), gpu_slice_length = FIX2INT(gpu_slice_length_object);

    RubiCLMemoryBuffer cpu_subset, gpu_subset;
    cpu_subset.type = mem_struct->type;
    gpu_subset.type = mem_struct->type;
    cpu_subset.buffer_entries = cpu_slice_length;
    gpu_subset.buffer_entries = gpu_slice_length;
    /* FIXME: Don't assume Integers here */
    cl_buffer_region cpu_region = { 0 /* Origin */, sizeof(int) * cpu_slice_length /* Region size */ };
    cl_buffer_region gpu_region = { sizeof(int) * cpu_slice_length /* Origin */, sizeof(int) * gpu_slice_length };
    cpu_subset.buffer = clCreateSubBuffer(mem_struct->buffer, CL_MEM_READ_WRITE, CL_BUFFER_CREATE_TYPE_REGION, &cpu_region, NULL);
    gpu_subset.buffer = clCreateSubBuffer(mem_struct->buffer, CL_MEM_READ_WRITE, CL_BUFFER_CREATE_TYPE_REGION, &gpu_region, NULL);

    runTaskOnDataset(&cpu_env, &cpu_subset, &cpu_task);
    runTaskOnDataset(&gpu_env, &gpu_subset, &gpu_task);

    clFinish(cpu_env.queue);
    clFinish(gpu_env.queue);

    releaseDeviceDataset(&cpu_subset);
    releaseDeviceDataset(&gpu_subset);

    return self;
}

/* Takes a code-generated Filter kernel and builds it for device then executes on dataset.
 * FIXME: Refactor pasted code from above method that is present here.
 *
 * @task_source_object: Ruby object storing the kernel as a String.
 * @task_name_object: Ruby object specifying the task within the source to enqueue.
 * @memory_struct_object: Ruby object containing RubiCLMemoryBuffer to process. */
static VALUE methodRunFilterTask(VALUE self, VALUE filter_task_source_object, VALUE filter_task_name_object,
                    VALUE scan_task_source_object, VALUE mem_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* dataset = mem_structPtrFromObj(mem_struct_object);
    environment->timings.computation_start = getTime("Filter Enqueue Started");

    /* Early termination for empty buffer */
    environment->timings.computation_total = 0;
    if (!dataset->buffer_entries) return self;

    /* Convert Objects into C types and build Kernel using environment ivar */
    RubiCLTask filter_task;
    char* filter_task_source = StringValuePtr(filter_task_source_object);
    char* filter_task_name = StringValuePtr(filter_task_name_object);
    char* scan_task_source = StringValuePtr(scan_task_source_object);
    buildTaskFromSource(environment, filter_task_source, filter_task_name, &filter_task);

    /* Enqueues the task to run on the dataset specified by the RubiCLMemoryBuffer */
    RubiCLMemoryBuffer presence, prescan;
    computePresenceArrayForDataset(environment, dataset, &filter_task, &presence);
    exclusivePrefixSum(environment, &presence, scan_task_source, &prescan);
    filterByScatteredWrites(environment, dataset, &presence, &prescan);
    releaseTemporaryFilterBuffers(&presence, &prescan);

    environment->timings.computation_total = getTime("Filter Enqueue Finished") - environment->timings.computation_start;
    return self;
}

static VALUE methodRunHybridFilterTask(VALUE self, VALUE filter_task_source_object, VALUE filter_task_name_object, VALUE cpu_scan_source,
        VALUE gpu_scan_source, VALUE memory_struct_object, VALUE cpu_slice_length_object, VALUE gpu_slice_length_object) {
    cl_int ret;

    RubiCLHybridEnvironment* environment;
    VALUE environment_object = rb_iv_get(self, "@environment");
    Data_Get_Struct(environment_object, RubiCLHybridEnvironment, environment);

    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(memory_struct_object);
    /* Early termination for empty buffer */
    if (!mem_struct->buffer_entries) return self;

    /* Dummy env for each individual device */
    RubiCLEnvironment cpu_env = { environment->cpu_device_id, environment->context, environment->cpu_queue };
    RubiCLEnvironment gpu_env = { environment->gpu_device_id, environment->context, environment->gpu_queue };

    RubiCLTask cpu_filter_task, gpu_filter_task;
    char* filter_task_source = StringValuePtr(filter_task_source_object);
    char* filter_task_name = StringValuePtr(filter_task_name_object);
    buildTaskFromSource(&cpu_env, filter_task_source, filter_task_name, &cpu_filter_task);
    buildTaskFromSource(&gpu_env, filter_task_source, filter_task_name, &gpu_filter_task);

    /* Create proportional sub-buffers and run tasks */
    int cpu_slice_length = FIX2INT(cpu_slice_length_object), gpu_slice_length = FIX2INT(gpu_slice_length_object);


    RubiCLMemoryBuffer cpu_subset, gpu_subset;
    cpu_subset.type = mem_struct->type;
    gpu_subset.type = mem_struct->type;
    cpu_subset.buffer_entries = cpu_slice_length;
    gpu_subset.buffer_entries = gpu_slice_length;
    /* FIXME: Don't assume Integers here */
    cl_buffer_region cpu_region = { 0 /* Origin */, sizeof(int) * cpu_slice_length /* Region size */ };
    cl_buffer_region gpu_region = { sizeof(int) * cpu_slice_length /* Origin */, sizeof(int) * gpu_slice_length };
    cpu_subset.buffer = clCreateSubBuffer(mem_struct->buffer, CL_MEM_READ_WRITE, CL_BUFFER_CREATE_TYPE_REGION, &cpu_region, NULL);
    gpu_subset.buffer = clCreateSubBuffer(mem_struct->buffer, CL_MEM_READ_WRITE, CL_BUFFER_CREATE_TYPE_REGION, &gpu_region, NULL);

    RubiCLMemoryBuffer cpu_presence, gpu_presence,  cpu_prescan, gpu_prescan;

    /* I swear I'm seeing double... */

    computePresenceArrayForDataset(&cpu_env, &cpu_subset, &cpu_filter_task, &cpu_presence);
    computePresenceArrayForDataset(&gpu_env, &gpu_subset, &gpu_filter_task, &gpu_presence);

    exclusivePrefixSum(&cpu_env, &cpu_presence, StringValuePtr(cpu_scan_source), &cpu_prescan);
    exclusivePrefixSum(&gpu_env, &gpu_presence, StringValuePtr(gpu_scan_source), &gpu_prescan);

    filterByScatteredWrites(&cpu_env, &cpu_subset, &cpu_presence, &cpu_prescan);
    filterByScatteredWrites(&gpu_env, &gpu_subset, &gpu_presence, &gpu_prescan);

    clFinish(cpu_env.queue);
    clFinish(gpu_env.queue);

    releaseTemporaryFilterBuffers(&cpu_presence, &cpu_prescan);
    releaseTemporaryFilterBuffers(&gpu_presence, &gpu_prescan);

    mem_struct->buffer_entries = cpu_subset.buffer_entries + gpu_subset.buffer_entries;

    /* New concatenated cl_mem buffer.
     * FIXME: Assuming integers again... */
    cl_mem old_buffer = mem_struct->buffer;
    clFinish(environment->cpu_queue);

    mem_struct->buffer = clCreateBuffer(
        cpu_env.context,                            // Context
        CL_MEM_READ_WRITE,                          // Flags
        mem_struct->buffer_entries * sizeof(int),   // Size
        NULL,                                    // Host Ptr
        &ret                                        // Ret
    );

    /* Copy CPU Segment into new buffer... */
    clEnqueueCopyBuffer(
        environment->cpu_queue,                     // Command queue
        cpu_subset.buffer,                          // Source buffer
        mem_struct->buffer,                         // Destination buffer
        0,                                          // Source offset
        0,                                          // Destination offset
        sizeof(int) * cpu_subset.buffer_entries,    // Copied data size
        0,                                          // Preceding events
        NULL,                                       // Event list
        NULL                                        // Produced event object
    );
    /* ... and the GPU segment */
    clEnqueueCopyBuffer(
        environment->cpu_queue,                     // Command queue
        gpu_subset.buffer,                          // Source buffer
        mem_struct->buffer,                         // Destination buffer
        0,                                          // Source offset
        sizeof(int) * cpu_subset.buffer_entries,    // Destination offset
        sizeof(int) * gpu_subset.buffer_entries,    // Copied data size
        0,                                          // Preceding events
        NULL,                                       // Event list
        NULL                                        // Produced event object
    );
    clFinish(environment->cpu_queue);

    releaseDeviceDataset(&cpu_subset);
    releaseDeviceDataset(&gpu_subset);
    clReleaseMemObject(old_buffer);


    return self;
}

static VALUE methodRunBraidTask(VALUE self, VALUE task_source_object, VALUE task_name_object,
                    VALUE fst_memstruct_object, VALUE snd_memstruct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* fsts = mem_structPtrFromObj(fst_memstruct_object);
    RubiCLMemoryBuffer* snds = mem_structPtrFromObj(snd_memstruct_object);

    char* task_source = StringValuePtr(task_source_object);
    char* task_name = StringValuePtr(task_name_object);

    RubiCLTask task;
    buildTaskFromSource(environment, task_source, task_name, &task);

    runTaskOnTupDataset(environment, &task, fsts, snds);
    clReleaseMemObject(snds->buffer);
    return fst_memstruct_object;
}

static VALUE methodRunTupMapTask(VALUE self, VALUE task_source_object, VALUE task_name_object,
                    VALUE fst_memstruct_object, VALUE snd_memstruct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* fsts = mem_structPtrFromObj(fst_memstruct_object);
    RubiCLMemoryBuffer* snds = mem_structPtrFromObj(snd_memstruct_object);

    char* task_source = StringValuePtr(task_source_object);
    char* task_name = StringValuePtr(task_name_object);

    RubiCLTask task;
    buildTaskFromSource(environment, task_source, task_name, &task);
    runTaskOnTupDataset(environment, &task, fsts, snds);

    return self;
}

static VALUE methodRunTupFilterTask(VALUE self, VALUE filter_task_source_object, VALUE filter_task_name_object,
                    VALUE scan_task_source_object, VALUE fst_memstruct_object, VALUE snd_memstruct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* fsts = mem_structPtrFromObj(fst_memstruct_object);
    RubiCLMemoryBuffer* snds = mem_structPtrFromObj(snd_memstruct_object);

    /* Early termination for empty buffer */
    if (!fsts->buffer_entries) return self;

    /* Convert Objects into C types and build Kernel using environment ivar */
    RubiCLTask filter_task;
    char* filter_task_source = StringValuePtr(filter_task_source_object);
    char* filter_task_name = StringValuePtr(filter_task_name_object);
    char* scan_task_source = StringValuePtr(scan_task_source_object);
    buildTaskFromSource(environment, filter_task_source, filter_task_name, &filter_task);

    /* Enqueues the task to run on the dataset specified by the RubiCLMemoryBuffer */
    RubiCLMemoryBuffer presence, prescan;
    computePresenceArrayForTupDataset(environment, fsts, snds, &filter_task, &presence);
    exclusivePrefixSum(environment, &presence, scan_task_source, &prescan);
    filterByScatteredWrites(environment, fsts, &presence, &prescan);
    filterByScatteredWrites(environment, snds, &presence, &prescan);
    releaseTemporaryFilterBuffers(&presence, &prescan);

    return self;
}


static VALUE methodRunExclusiveScanTask(VALUE self, VALUE scan_task_source_object, VALUE mem_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(mem_struct_object);

    char* scan_task_source = StringValuePtr(scan_task_source_object);

    RubiCLMemoryBuffer* result = malloc(sizeof(RubiCLMemoryBuffer));
    exclusivePrefixSum(environment, mem_struct, scan_task_source, result);
    clReleaseMemObject(mem_struct->buffer);
    mem_struct->buffer = result->buffer;

    return self;
}

static VALUE methodRunInclusiveScanTask(VALUE self, VALUE scan_task_source_object, VALUE braid_task_source_object,
                            VALUE braid_task_name_object, VALUE mem_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(mem_struct_object);

    char* scan_task_source = StringValuePtr(scan_task_source_object);

    RubiCLMemoryBuffer* result = malloc(sizeof(RubiCLMemoryBuffer));
    exclusivePrefixSum(environment, mem_struct, scan_task_source, result);

    char* braid_task_source = StringValuePtr(braid_task_source_object);
    char* braid_task_name = StringValuePtr(braid_task_name_object);

    RubiCLTask braid_task;
    buildTaskFromSource(environment, braid_task_source, braid_task_name, &braid_task);

    runTaskOnTupDataset(environment, &braid_task, result, mem_struct);
    clReleaseMemObject(mem_struct->buffer);
    mem_struct->buffer = result->buffer;

    return self;
}

static VALUE methodRunIntSortTask(VALUE self, VALUE sort_task_source_object, VALUE mem_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* mem_struct = mem_structPtrFromObj(mem_struct_object);

    int pow_two = 1;
    while ((pow_two <<= 1) < mem_struct->buffer_entries);

    char* sort_task_source = StringValuePtr(sort_task_source_object);
    RubiCLTask task;
    buildTaskFromSource(environment, sort_task_source, "bitonicSort", &task);

    /* If the dataset is not a power of two, BEGIN faff. */
    if (pow_two > mem_struct->buffer_entries) {
        /* Create a buffer with power-of-two length to hold the dataset and required padding.
         * Initialise the buffer with the padding:
         *      [P, P, ... ] */
        int padding_length = pow_two - mem_struct->buffer_entries;
        int* padded_buffer = malloc(pow_two * sizeof(int));
        for (int i = 0; i < padding_length; ++i) padded_buffer[i] = INT_MAX;

        RubiCLMemoryBuffer padded_buffer_struct;
        pinArrayForDevice(&environment->context, padded_buffer, pow_two, pow_two * sizeof(int), &padded_buffer_struct, INTEGER_BUFFER);
        clFinish(environment->queue);

        /* Append the dataset to the padded buffer as follows:
         *      [P, P, 1, 2, 3, 4, 5, 6] */
        clEnqueueCopyBuffer(
            environment->queue,                         // Command queue
            mem_struct->buffer,                         // Source buffer
            padded_buffer_struct.buffer,                // Destination buffer
            0,                                          // Source offset
            sizeof(int) * padding_length,               // Destination offset (After padding)
            sizeof(int) * mem_struct->buffer_entries,   // Copied data size
            0,                                          // Preceding events
            NULL,                                       // Event list
            NULL                                        // Produced event object
        );
        clFinish(environment->queue);

        /* Sort such that the padding propagates to the end:
         *      [1, 2, 3, 4, 5, 6, P, P] */
        integerBitonicSort(environment, &padded_buffer_struct, &task);

        /* Copy the first N elements of the sorted array back to the origin buffer:
         *      [1, 2, 3, 4, 5, 6] // [P, P] */
        clEnqueueCopyBuffer(
            environment->queue,                         // Command queue
            padded_buffer_struct.buffer,                // Source buffer
            mem_struct->buffer,                         // Destination buffer
            0,                                          // Source offset
            0,                                          // Destination offset
            sizeof(int) * mem_struct->buffer_entries,   // Copied data size
            0,                                          // Preceding events
            NULL,                                       // Event list
            NULL                                        // Produced event object
        );
        clReleaseMemObject(padded_buffer_struct.buffer);
    /* If the dataset length is a power of two, no faff is needed. */
    } else {
        integerBitonicSort(environment, mem_struct, &task);
    }

    return self;
}

/* Returns the number of elements that would remain in the buffer after a given filter task.
 *
 * @task_source_object: Ruby object containing the filter kernel to enqueue.
 * @source_size_object: Ruby object containing the length of the filter kernel's source.
 * @task_name_object: Ruby object containing the name of the filter task to enqueue.
 * @mem_struct_object: Ruby object containing the RubiCLMemoryBuffer to filter. */
static VALUE methodCountFilteredBuffer(VALUE self, VALUE task_source_object, VALUE task_name_object,
                            VALUE scan_task_source_object, VALUE mem_struct_object) {
    RubiCLEnvironment* environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* dataset = mem_structPtrFromObj(mem_struct_object);

    /* Convert Objects into C types and builds Kernel using environment ivar */
    char* task_source = StringValuePtr(task_source_object);
    char* task_name = StringValuePtr(task_name_object);
    RubiCLTask task;
    buildTaskFromSource(environment, task_source, task_name, &task);

    /* Enqueues the task to run on the dataset specified by the RubiCLMemoryBuffer */
    RubiCLMemoryBuffer presence, prescan;
    computePresenceArrayForDataset(environment, dataset, &task, &presence);
    exclusivePrefixSum(environment, &presence, StringValuePtr(scan_task_source_object), &prescan);

    VALUE result = INT2FIX(filteredBufferLength(environment, &presence, &prescan));
    releaseTemporaryFilterBuffers(&presence, &prescan);
    return result;
}

/* ~~ END Task Dispatching Methods ~~ */

static VALUE methodCleanUsedResources(VALUE self, VALUE mem_struct_object) {
    RubiCLEnvironment *environment = environmentPtrFromIvar(self);
    RubiCLMemoryBuffer* dataset = mem_structPtrFromObj(mem_struct_object);
    clFlush(environment->queue);
    clFinish(environment->queue);
    clReleaseMemObject(dataset->buffer);

    return self;
}

/* Used to give extension methods defined above to device class when RubiCLBackend module is included. */
void Init_rubicl_backend() {
    VALUE RubiCLDeviceBackend = rb_define_module("RubiCLDeviceBackend");
    rb_define_private_method(RubiCLDeviceBackend, "initialize_GPU_environment", methodInitGPUEnvironment, 0);
    rb_define_private_method(RubiCLDeviceBackend, "initialize_CPU_environment", methodInitCPUEnvironment, 0);
    rb_define_private_method(RubiCLDeviceBackend, "initialize_hybrid_environment", methodInitHybridEnvironment, 0);
    rb_define_private_method(RubiCLDeviceBackend, "clean_used_resources", methodCleanUsedResources, 1);

    VALUE RubiCLBufferBackend = rb_define_module("RubiCLBufferBackend");
    rb_define_private_method(RubiCLBufferBackend, "create_memory_buffer", methodCreateMemoryBuffer, 2);
    rb_define_private_method(RubiCLBufferBackend, "transfer_integer_dataset_to_buffer", methodLoadIntDataset, 2);
    rb_define_private_method(RubiCLBufferBackend, "create_pinned_integer_buffer", methodPinIntDataset, 1);
    rb_define_private_method(RubiCLBufferBackend, "create_pinned_intfile_buffer", methodPinIntFile, 1);
    rb_define_private_method(RubiCLBufferBackend, "create_pinned_double_buffer", methodPinDoubleDataset, 1);
    rb_define_private_method(RubiCLBufferBackend, "retrieve_integer_dataset_from_buffer", methodRetrieveIntDataset, 1);
    rb_define_private_method(RubiCLBufferBackend, "retrieve_pinned_integer_dataset_from_buffer", methodRetrievePinnedIntDataset, 1);
    rb_define_private_method(RubiCLBufferBackend, "retrieve_pinned_double_dataset_from_buffer", methodRetrievePinnedDoubleDataset, 1);
    rb_define_private_method(RubiCLBufferBackend, "buffer_length", methodBufferLength, 1);
    rb_define_private_method(RubiCLBufferBackend, "last_memory_duration", methodLastMemoryDuration, 0);
    rb_define_private_method(RubiCLBufferBackend, "last_computation_duration", methodLastComputationDuration, 0);

    VALUE RubiCLTaskBackend = rb_define_module("RubiCLTaskBackend");
    rb_define_private_method(RubiCLTaskBackend, "sum_integer_buffer", methodSumIntegerBuffer, 2);
    rb_define_private_method(RubiCLTaskBackend, "count_post_filter", methodCountFilteredBuffer, 4);
    rb_define_private_method(RubiCLTaskBackend, "run_map_task", methodRunMapTask, 3);
    rb_define_private_method(RubiCLTaskBackend, "run_hybrid_map_task", methodRunHybridMapTask, 5);
    rb_define_private_method(RubiCLTaskBackend, "run_filter_task", methodRunFilterTask, 4);
    rb_define_private_method(RubiCLTaskBackend, "run_hybrid_filter_task", methodRunHybridFilterTask, 7);
    rb_define_private_method(RubiCLTaskBackend, "run_braid_task", methodRunBraidTask, 4);
    rb_define_private_method(RubiCLTaskBackend, "run_tupmap_task", methodRunTupMapTask, 4);
    rb_define_private_method(RubiCLTaskBackend, "run_tupfilter_task", methodRunTupFilterTask, 5);
    rb_define_private_method(RubiCLTaskBackend, "run_exclusive_scan_task", methodRunExclusiveScanTask, 2);
    rb_define_private_method(RubiCLTaskBackend, "run_inclusive_scan_task", methodRunInclusiveScanTask, 4);
    rb_define_private_method(RubiCLTaskBackend, "sort_integer_buffer", methodRunIntSortTask, 2);
    rb_define_private_method(RubiCLTaskBackend, "last_computation_duration", methodLastComputationDuration, 0);
    rb_define_private_method(RubiCLTaskBackend, "last_pipeline_duration", methodLastPipelineDuration, 0);
}
