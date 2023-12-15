shader_type spatial;

uniform vec4 albedo:source_color;
uniform sampler2D texture_albedo:source_color,filter_linear_mipmap,repeat_enable;
uniform vec3 uv_scale;
uniform vec3 uv_offset;

instance uniform bool fade_enabled;
instance uniform vec3 fade_position;
uniform float fade_min;
uniform float fade_max;

void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
}

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	if (fade_enabled) {
		const vec3 magic = vec3(0.06711056f, 0.00583715f, 52.9829189f);
		float fade_distance = length(CAMERA_POSITION_WORLD - fade_position);
		float fade = smoothstep(fade_min, fade_max, fade_distance);
		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			discard;
		}
	}
}
