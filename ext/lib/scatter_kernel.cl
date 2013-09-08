__kernel void ScatterFilterKernel(
    __global int *input_data,
    __global int *presence,
    __global int *index,
    __global int *output_data
) {
    const uint global_id = get_global_id(0);

    int destination;
    int is_present = presence[global_id];

    if (is_present) {
        destination = index[global_id];
        output_data[destination] = input_data[global_id];
    }
}
