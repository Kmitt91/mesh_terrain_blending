//script for Godot 3.3.x and 4.0 (dev)
shader_type spatial;

uniform vec3 n = vec3(0.0, 1.0, 0.0);

uniform float triplanar_scale = 0.25;
uniform float blend_size = 1.0;
uniform float blend_offset = 0.0;

uniform sampler2D main_albedo : hint_albedo;
uniform sampler2D blend_albedo : hint_albedo;
uniform sampler2D transition_mask;

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness = 1.0;
varying vec3 uv1_power_normal;



void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	
	uv1_power_normal=pow(abs(mat3(WORLD_MATRIX) * NORMAL),vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0f)).xyz * triplanar_scale;
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}


vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
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
	
	vec3 main_col = texture(main_albedo, UV).rgb;
	vec3 blend_col = triplanar_texture(blend_albedo, uv1_power_normal, uv1_triplanar_pos).rgb;
	
	float blend_mask = texture(transition_mask, UV).r;
	float blend = overlay(dist, blend_mask);
	
	ALBEDO = mix(blend_col, main_col, blend);
}




