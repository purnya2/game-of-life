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

uint get_index(int x, int y, int z) {
    if (x < 0 || x >= width || y < 0 || y >= height || z < 0 || z >= depth) {
        return 0xFFFFFFFFu; 
    }
    return uint(x + y * width + z * width * height);
}

bool is_cell_alive(int x, int y, int z) {
    // Return false (dead) for cells outside the grid
    if (x < 0 || x >= width || y < 0 || y >= height || z < 0 || z >= depth) {
        return false;
    }
    uint idx = uint(x + y * width + z * width * height);

    uint current_state = uint(input_buffer.data[idx]);
    return current_state == 1u;
}

void main(){
    ivec3 pos = ivec3(gl_GlobalInvocationID.xyz);

    if (pos.x >= width || pos.y >= height || pos.z >= depth) {
        return;
    }

    const ivec3 offsets[26] = ivec3[26](
        // Face-adjacent neighbors (6)
        ivec3(1, 0, 0), ivec3(-1, 0, 0),  // right/left
        ivec3(0, 1, 0), ivec3(0, -1, 0),  // up/down
        ivec3(0, 0, 1), ivec3(0, 0, -1),  // front/back
        
        // Edge-adjacent neighbors (12)
        ivec3(1, 1, 0), ivec3(1, -1, 0), ivec3(-1, 1, 0), ivec3(-1, -1, 0),  // xy edges
        ivec3(1, 0, 1), ivec3(1, 0, -1), ivec3(-1, 0, 1), ivec3(-1, 0, -1),  // xz edges
        ivec3(0, 1, 1), ivec3(0, 1, -1), ivec3(0, -1, 1), ivec3(0, -1, -1),  // yz edges
        
        // Corner-adjacent neighbors (8)
        ivec3(1, 1, 1), ivec3(1, 1, -1), ivec3(1, -1, 1), ivec3(1, -1, -1),
        ivec3(-1, 1, 1), ivec3(-1, 1, -1), ivec3(-1, -1, 1), ivec3(-1, -1, -1)
    );

    uint current_idx = get_index(pos.x, pos.y, pos.z);
    uint live_neighbors = 0;

    // Count all 26 neighbors, treating out-of-bounds as dead
    for (int i = 0; i < 26; i++) {
        if (is_cell_alive(
            pos.x + offsets[i].x,
            pos.y + offsets[i].y,
            pos.z + offsets[i].z
        )) {
            live_neighbors++;
        }
    }

    uint current_state = uint(input_buffer.data[current_idx]);
    
    if (current_state == 1u) {
        output_buffer.data[current_idx] = (live_neighbors >= 2u && live_neighbors <= 5u) ? uint8_t(1) : uint8_t(0);
    } else {
        output_buffer.data[current_idx] = (live_neighbors >= 5u && live_neighbors <= 6u) ? uint8_t(1) : uint8_t(0);
    }

}