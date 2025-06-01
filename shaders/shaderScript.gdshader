shader_type spatial;

uniform sampler2D atlas_tex : source_color, repeat_enable;
uniform vec2 atlas_tiles = vec2(4.0, 4.0);
uniform float texture_scale = 1.0;

varying float v_tile_index;
varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
    v_tile_index = INSTANCE_CUSTOM.r * 255.0;
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec2 get_tile_offset(float index) {
    float col = mod(index, atlas_tiles.x);
    float row = floor(index / atlas_tiles.x);
    return vec2(col / atlas_tiles.x, row / atlas_tiles.y);
}

vec3 triplanar_blend(vec3 n) {
    vec3 blend = abs(n);
    blend = pow(blend, vec3(4.0));
    return blend / (blend.x + blend.y + blend.z);
}

void fragment() {
    vec3 worldPos = v_world_pos;
    vec3 worldNormal = normalize(v_world_normal);
    
    // Calculate blend weights
    vec3 blend = triplanar_blend(worldNormal);
    
    // Create UVs with edge alignment
    vec3 scaledPos = worldPos * texture_scale;
    
    // Adjust UVs to start at edges rather than centers
    vec2 uvX = fract(scaledPos.yz - 0.5);
    vec2 uvY = fract(scaledPos.xz - 0.5);
    vec2 uvZ = fract(scaledPos.xy - 0.5);
    
    // Atlas mapping
    vec2 tileOffset = get_tile_offset(v_tile_index);
    vec2 tileScale = vec2(1.0) / atlas_tiles;

    // Sample textures
    vec3 colX = texture(atlas_tex, tileOffset + uvX * tileScale).rgb;
    vec3 colY = texture(atlas_tex, tileOffset + uvY * tileScale).rgb;
    vec3 colZ = texture(atlas_tex, tileOffset + uvZ * tileScale).rgb;

    // Combine colors
    vec3 albedo = colX * blend.x + colY * blend.y + colZ * blend.z;
    
        // Improved lighting
    float lighting = clamp(dot(worldNormal, vec3(0.0, 1.0, 0.0)) + 0.5, 0.5, 1.0);
    ALBEDO = albedo * lighting;
}