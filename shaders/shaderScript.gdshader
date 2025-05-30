shader_type spatial;

uniform sampler2D atlas_tex;
uniform vec2 atlas_size = vec2(4.0, 4.0); // Set to your grid size
uniform int tile_index = 0; // Used for normal meshes
uniform bool use_instance_data = true; // Switch for MultiMesh vs normal

varying float v_tile_index;

void vertex() {
    if (use_instance_data) {
        v_tile_index = INSTANCE_CUSTOM.r * 255.0;
    } else {
        v_tile_index = float(tile_index);
    }
}

vec2 get_atlas_uv(vec2 uv, float index) {
    int col = int(mod(index, atlas_size.x));
    int row = int(floor(index / atlas_size.x));
    return (vec2(float(col), float(row)) + uv) / atlas_size;
}

void fragment() {
    vec2 atlas_uv = get_atlas_uv(UV, v_tile_index);
    vec3 albedo = texture(atlas_tex, atlas_uv).rgb;

    ALBEDO = albedo;
}
