__kernel void IntegerScatterFilterKernel(
    __global const int *input_data,
    __global const int *presence,
    __global const int *index,
    __global int *output_data
) {
    const uint global_id = get_global_id(0);

    const int is_present = presence[global_id];

    if (is_present) {
        const int destination = index[global_id];
        output_data[destination] = input_data[global_id];
    }
}
