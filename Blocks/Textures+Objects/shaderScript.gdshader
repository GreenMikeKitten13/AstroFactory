shader_type spatial;
render_mode unshaded;

uniform sampler2D atlas_tex;
uniform vec2 atlas_size = vec2(4.0, 4.0);
uniform int index = 0;

vec2 get_atlas_uv(vec2 uv) {
	int col = int(mod(float(index), atlas_size.x));
	int row = int(floor(float(index) / atlas_size.x));
	return (vec2(float(col), float(row)) + uv) / atlas_size;
}

void fragment() {
	vec2 atlas_uv = get_atlas_uv(UV);
	ALBEDO = texture(atlas_tex, atlas_uv).rgb;
}

