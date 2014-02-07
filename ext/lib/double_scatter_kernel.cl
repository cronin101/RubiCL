__kernel void DoubleScatterFilterKernel(
    __global const double *input_data,
    __global const int *presence,
    __global const int *index,
    __global double *output_data
) {
    const uint global_id = get_global_id(0);

    const int is_present = presence[global_id];

    if (is_present) {
        const int destination = index[global_id];
        output_data[destination] = input_data[global_id];
    }
}
