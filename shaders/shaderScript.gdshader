shader_type spatial;

uniform sampler2D atlas_tex;
uniform vec2 atlas_size = vec2(4.0, 4.0); // Tiles in the atlas
uniform bool use_instance_data = true;
uniform int tile_index = 0;

varying float v_tile_index;
varying vec3 world_pos;

void vertex() {
    if (use_instance_data) {
        v_tile_index = INSTANCE_CUSTOM.r * 255.0;
    } else {
        v_tile_index = float(tile_index);
    }

    // Pass world position to fragment
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec2 get_tile_offset(float index) {
    float col = mod(index, atlas_size.x);
    float row = floor(index / atlas_size.x);
    return vec2(col, row) / atlas_size;
}

vec3 triplanar_blend(vec3 normal) {
    vec3 blend = abs(normal);
    blend = normalize(max(blend, 0.00001));
    return blend / (blend.x + blend.y + blend.z);
}

void fragment() {
    vec3 blend = triplanar_blend(NORMAL);
    vec3 wp = world_pos * 1.25; // 1.5 3.0 5.0 10.0 1.0 0.75 0.25  0.5

    vec2 x_uv = fract(wp.yz);
    vec2 y_uv = fract(wp.xz);
    vec2 z_uv = fract(wp.xy);

    vec2 tile_offset = get_tile_offset(v_tile_index);
    vec2 tile_scale = vec2(1.0) / atlas_size;

    x_uv = tile_offset + x_uv * tile_scale;
    y_uv = tile_offset + y_uv * tile_scale;
    z_uv = tile_offset + z_uv * tile_scale;

    vec3 x_col = texture(atlas_tex, x_uv).rgb;
    vec3 y_col = texture(atlas_tex, y_uv).rgb;
    vec3 z_col = texture(atlas_tex, z_uv).rgb;

    vec3 final_color = x_col * blend.x + y_col * blend.y + z_col * blend.z;

    ALBEDO = final_color;
}