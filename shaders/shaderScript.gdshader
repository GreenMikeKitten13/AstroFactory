shader_type spatial;

uniform sampler2D atlas_tex;
uniform vec2 atlas_size = vec2(4.0, 4.0);
uniform bool use_instance_data = true;
uniform int tile_index = 0;

varying float v_tile_index;

void vertex() {
    if (use_instance_data) {
        v_tile_index = INSTANCE_CUSTOM.r * 255.0;
    } else {
        v_tile_index = float(tile_index);
    }
}

vec2 get_tile_offset(float index) {
    float col = mod(index, atlas_size.x);
    float row = floor(index / atlas_size.x);
    return vec2(col, row) / atlas_size;
}

vec3 triplanar_texture(vec3 local_pos, vec3 normal, float index) {
    vec2 tile_offset = get_tile_offset(index);
    vec2 tile_scale = vec2(1.0) / atlas_size;

    vec3 blend = abs(normal);
    blend = normalize(max(blend, 0.0001));
    blend /= (blend.x + blend.y + blend.z);

    // Use local box-space coordinates to avoid world-position stretching
    vec2 uv_x = fract(local_pos.yz);
    vec2 uv_y = fract(local_pos.xz);
    vec2 uv_z = fract(local_pos.xy);

    uv_x = tile_offset + uv_x * tile_scale;
    uv_y = tile_offset + uv_y * tile_scale;
    uv_z = tile_offset + uv_z * tile_scale;

    vec3 tex_x = texture(atlas_tex, uv_x).rgb;
    vec3 tex_y = texture(atlas_tex, uv_y).rgb;
    vec3 tex_z = texture(atlas_tex, uv_z).rgb;

    return tex_x * blend.x + tex_y * blend.y + tex_z * blend.z;
}

void fragment() {
    vec3 color = triplanar_texture(VERTEX, NORMAL, v_tile_index);
    ALBEDO = color;
}