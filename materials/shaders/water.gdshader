shader_type spatial;
render_mode cull_disabled;

uniform vec3 albedo:source_color;
uniform float specular:hint_range(0.0, 1.0) = 0.5;
uniform float roughness:hint_range(0.0, 1.0) = 0.125;
uniform sampler2D noise_texture;
uniform sampler2D depth_texture:source_color, hint_depth_texture;
uniform float depth_density = 1;

varying float noise;

void vertex() {
	noise = texture(noise_texture, UV + (TIME * .01)).r * 0.25;
	VERTEX.y -= noise;
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	depth = PROJECTION_MATRIX[3].z / (depth + PROJECTION_MATRIX[2].z) + VERTEX.z;
	depth = exp(-depth * depth_density);

	float edge = smoothstep(.95, 1, depth);

	ALBEDO = albedo + edge;
	ALPHA = 1. - depth;
	ROUGHNESS = roughness;
	SPECULAR = specular;

	NORMAL.y -= noise;
	NORMAL = normalize(NORMAL);
}
