#[compute]
#version 450
#extension GL_EXT_shader_8bit_storage : require

layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;

layout(set = 0, binding = 0)  restrict readonly buffer InputBuffer{
    uint8_t data[];
}
input_buffer;

layout(set = 0, binding = 1) restrict writeonly buffer OutputBuffer{
    uint8_t data[];
}
output_buffer;

layout(set = 0, binding = 2)  uniform Dimensions {
    int width;
    int height;
    int depth;
    int dum;
};

layout(set = 0, binding = 3)  uniform Config {
    int min_survive;
    int max_survive;
    int min_born;
    int max_born;
};

uint get_index(int x, int y, int z) {
    if (x < 0 || x >= width || y < 0 || y >= height || z < 0 || z >= depth) {
        return 0xFFFFFFFFu;
    }
    return uint(x + y * width + z * width * height);
}

bool is_cell_alive(int x, int y, int z) {

    uint idx = uint(x + y * width + z * width * height);

    uint current_state = uint(input_buffer.data[idx]);
    return current_state == 1u;
}

void main(){
    ivec3 pos = ivec3(gl_GlobalInvocationID.xyz);

    if (pos.x >= width || pos.y >= height || pos.z >= depth) {
        return;
    }

    uint current_idx = get_index(pos.x, pos.y, pos.z);
    uint live_neighbors = 0;

    // Count all 26 neighbors - unrolled for performance
    // Face-adjacent neighbors (6)
    if (is_cell_alive(pos.x + 1, pos.y, pos.z)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y, pos.z)) live_neighbors++;
    if (is_cell_alive(pos.x, pos.y + 1, pos.z)) live_neighbors++;
    if (is_cell_alive(pos.x, pos.y - 1, pos.z)) live_neighbors++;
    if (is_cell_alive(pos.x, pos.y, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x, pos.y, pos.z - 1)) live_neighbors++;

    // Edge-adjacent neighbors (12)
    if (is_cell_alive(pos.x + 1, pos.y + 1, pos.z)) live_neighbors++;
    if (is_cell_alive(pos.x + 1, pos.y - 1, pos.z)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y + 1, pos.z)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y - 1, pos.z)) live_neighbors++;
    if (is_cell_alive(pos.x + 1, pos.y, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x + 1, pos.y, pos.z - 1)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y, pos.z - 1)) live_neighbors++;
    if (is_cell_alive(pos.x, pos.y + 1, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x, pos.y + 1, pos.z - 1)) live_neighbors++;
    if (is_cell_alive(pos.x, pos.y - 1, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x, pos.y - 1, pos.z - 1)) live_neighbors++;

    // Corner-adjacent neighbors (8)
    if (is_cell_alive(pos.x + 1, pos.y + 1, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x + 1, pos.y + 1, pos.z - 1)) live_neighbors++;
    if (is_cell_alive(pos.x + 1, pos.y - 1, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x + 1, pos.y - 1, pos.z - 1)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y + 1, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y + 1, pos.z - 1)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y - 1, pos.z + 1)) live_neighbors++;
    if (is_cell_alive(pos.x - 1, pos.y - 1, pos.z - 1)) live_neighbors++;

    uint current_state = uint(input_buffer.data[current_idx]);

    if (current_state == 1u) {
        output_buffer.data[current_idx] = (live_neighbors >= uint(min_survive) && live_neighbors <= uint(max_survive)) ? uint8_t(1) : uint8_t(0);
    } else {
        output_buffer.data[current_idx] = (live_neighbors >= uint(min_born) && live_neighbors <= uint(max_born)) ? uint8_t(1) : uint8_t(0);
    }

}