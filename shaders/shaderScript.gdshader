shader_type spatial;

uniform sampler2D atlas_tex;
uniform vec2 atlas_size = vec2(4.0, 4.0);

varying float tile_index;

vec2 get_atlas_uv(vec2 uv, float index) {
	int col = int(mod(index, atlas_size.x));
	int row = int(floor(index / atlas_size.x));
	return (vec2(float(col), float(row)) + uv) / atlas_size;
}

void vertex() {
	tile_index = INSTANCE_CUSTOM.r * 255.0;
}

void fragment() {
	vec2 atlas_uv = get_atlas_uv(UV, tile_index);
	vec3 albedo = texture(atlas_tex, atlas_uv).rgb;

	ALBEDO = albedo;
}
