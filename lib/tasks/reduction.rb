module Hadope
  class Reduction
    def initialize(type)
      @type = type
    end
  end

  class CPUReduction < Reduction
    def kernel
<<KERNEL
_kernel
void reduce(__global #{@type}* input,
            __const int block,
            __const int length,
            __global #{@type}* result) {

  int global_index = get_global_id(0) * block;
  #{type} accumulator = INFINITY;
  int upper_bound = (get_global_id(0) + 1) * block;
  if (upper_bound > length) upper_bound = length;
  while (global_index < upper_bound) {
    #{type} element = input[global_index];
    accumulator = (accumulator < element) ? accumulator : element;
    global_index++;
  }
  result[get_group_id(0)] = accumulator;
}
KERNEL
    end
  end

  class GPUReduction < Reduction
    def kernel
<<KERNEL
_kernel
void reduce(__global #{type}* input,
            __local #{type} scratch,
            __const int length,
            __global #{type}* result) {

  int global_index = get_global_id(0);
  #{type} accumulator = INFINITY;
  // Loop sequentially over chunks of input vector
  while (global_index < length) {
    #{type} element = input[global_index];
    accumulator = (accumulator < element) ? accumulator : element;
    global_index += get_global_size(0);
  }

  // Perform parallel reduction
  int local_index = get_local_id(0);
  scratch[local_index] = accumulator;
  barrier(CLK_LOCAL_MEM_FENCE);
  for(int offset = get_local_size(0) / 2;
      offset > 0;
      offset = offset / 2) {
    if (local_index < offset) {
      #{type} other = scratch[local_index + offset];
      #{type} mine = scratch[local_index];
      scratch[local_index] = (mine < other) ? mine : other;
    }
    barrier(CLK_LOCAL_MEM_FENCE);
  }
  if (local_index == 0) {
    result[get_group_id(0)] = scratch[0];
  }
}
KERNEL
    end
  end
end
