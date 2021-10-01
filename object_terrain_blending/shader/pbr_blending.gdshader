shader_type spatial;

uniform vec3 n = vec3(0.0, 1.0, 0.0);

uniform float triplanar_scale = 0.05;
uniform float blend_size = 1.0;
uniform float blend_offset = 0.0;

uniform sampler2D transition_mask;

uniform sampler2D main_albedo : hint_albedo;
uniform sampler2D main_normal : hint_normal;
uniform sampler2D main_roughness : hint_white;
uniform sampler2D main_ao: hint_white;

uniform sampler2D blend_albedo : hint_albedo;
uniform sampler2D blend_normal : hint_normal;
uniform sampler2D blend_roughness : hint_white;
uniform sampler2D blend_ao: hint_white;

varying vec3 uv_triplanar_pos;
varying vec3 uv_power_normal;

void vertex(){
	
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	
	uv_power_normal = pow(abs(mat3(WORLD_MATRIX) * NORMAL), vec3(1.0));
	uv_triplanar_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0f)).xyz * triplanar_scale;
	uv_power_normal /= dot(uv_power_normal, vec3(1.0));
	uv_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_triplanar_pos, vec3 p_weights) {
	vec4 samp = vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

float overlay(float a, float b){
	if(a < 0.5){
		return a * b * 2.0;
	}else{
		return 1.0- 2.0 * (1.0 - a)*(1.0 - b);
	}
}

void fragment(){
	vec3 p = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = dot(p, n);
	dist = max(min((dist + blend_offset) * blend_size - 0.5, 1.0), 0.0);
	
	
	vec4 m_col = texture(main_albedo, UV);
	vec3 m_norm = texture(main_normal, UV).rgb;
	float m_rough = texture(main_roughness, UV).r;
	float m_ao = texture(main_ao, UV).r;
	
	vec4 b_col = triplanar_texture(blend_albedo, uv_triplanar_pos, uv_power_normal);
	vec3 b_norm = triplanar_texture(blend_normal, uv_triplanar_pos, uv_power_normal).rgb;
	float b_rough = triplanar_texture(blend_roughness, uv_triplanar_pos, uv_power_normal).r;
	float b_ao = triplanar_texture(blend_ao, uv_triplanar_pos, uv_power_normal).r;
	
	
	float blend_mask = texture(transition_mask, UV).r;
	float blend = overlay(dist, blend_mask);
	
	ALBEDO = mix(b_col.rgb, m_col.rgb, blend);
	//Godot 3.3 normalmap:
	NORMALMAP = mix(b_norm, m_norm, blend);
	//Godot 4.0dev normalmap:
	//NORMAL_MAP = mix(b_norm, m_norm, blend);
	ROUGHNESS = mix(b_rough, m_rough, blend);
	AO = mix(b_ao, m_ao, blend);
	AO_LIGHT_AFFECT = 0.5;
}