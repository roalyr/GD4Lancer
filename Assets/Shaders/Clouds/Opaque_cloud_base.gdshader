shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	
	// Blending and culling.
	blend_mix,
	cull_disabled,
	
	unshaded,
	diffuse_lambert, 
	specular_disabled,
	
	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : source_color;
uniform vec4 albedo_glow_near : source_color;
uniform vec4 albedo_detail_distant : source_color;

uniform sampler2D distant_detail_noise;
uniform sampler2D normal_detail_minor_noise;

uniform float normal_detail_factor = 1.0;

uniform float distant_detail_phase = 1.0;
uniform float distant_detail_factor = 1.0;
uniform float distant_detail_strength = 1.0;

uniform float fade = 0;

uniform float rim_strength = 1.0;
uniform float rim_exponent : hint_range(0.0, 10.0) = 1.0;



uniform float color_power_r = 1.0;
uniform float color_power_g = 1.0;
uniform float color_power_b = 1.0;
uniform float color_multiplier_r = 1.0;
uniform float color_multiplier_g = 1.0;
uniform float color_multiplier_b = 1.0;

uniform float dither_darken :  hint_range(0.5, 1.0, 5e-4) = 0.75;

const float dither_x = 172.7;
const float dither_y = 232.6;
const float dither_r = 105.5;
const float dither_g = 99.0;
const float dither_b = 110.0;


const float pi = 3.1415926535;

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness = 10.0;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale = vec3(100.0);
uniform vec3 uv1_offset;

vec3 interleaved_gradient_noise(vec2 frag_coord) {
	vec3 dither = vec3(dot(vec2(dither_x, dither_y), frag_coord));
	dither.rgb = fract(dither.rgb / vec3(dither_r, dither_g, dither_b));
	return (dither.rgb - vec3(dither_darken)) / 255.0;
}


void vertex() {
	vec3 normal = NORMAL;
	TANGENT = vec3(0.0,0.0,-1.0) * abs(normal.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(normal.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(normal.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale*1e-3 + uv1_offset*1e-2;
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

void fragment()
{
	// Get tangent, binormal and normal of the vertex.
	vec3 N = normalize(NORMAL);
	vec3 T = normalize(TANGENT);
	vec3 B = normalize(BINORMAL);
	
	// Get texture data.
	// Normal textures.
	vec4 nm_detail_minor_noise = triplanar_texture(normal_detail_minor_noise,uv1_power_normal,uv1_triplanar_pos);
		// Transform the RGB values of the normal map to the range [-1, 1].
	vec3 nm_detail_minor_noise_normalized = normalize(nm_detail_minor_noise.rgb * 2.0 - 1.0);
		// Transform normal map normal from tangent space to view space.
	vec3 nm_normal_detail_minor_view = normalize(mat3(T, B, N) * nm_detail_minor_noise_normalized);
	
	// Binary textures.
	float bm_distant_detail_noise = sin(triplanar_texture(distant_detail_noise,uv1_power_normal,uv1_triplanar_pos).r*pi+distant_detail_phase);
	
	// Calculate the dot product between the normal and view direction.
	float dt = clamp(dot(NORMAL, VIEW), 1e-6, 1.0);
	float dt_normal_detail_minor = clamp(dot(nm_normal_detail_minor_view, VIEW), 1e-6, 1.0);
	float dt_distant_detail = dt + dt * bm_distant_detail_noise * (1.0 - dt);
	
	// Attenuate the dot product.
	float rim_detail_distant = clamp(pow(dt_distant_detail, rim_exponent)*rim_strength, 1e-6, 1.0);
	float rim_normal_detail_minor = clamp(pow(dt_normal_detail_minor, rim_exponent)*rim_strength, 1e-6, 1.0);
	
	// Fade distances.
	float dist = length(VERTEX);
	float fd = 1.0-clamp(smoothstep(0.0, fade, dist), 1e-6, 1.0); // fades out
	
	// Main color. Adjusted by noise maps.
	ALBEDO = albedo.rgb * COLOR.rgb
		*(1.0-rim_normal_detail_minor*fd*normal_detail_factor)
		;
		
	// Near field.
	ALBEDO += albedo_glow_near.rgb*fd
		;
	
	// Details field.
	ALBEDO += albedo_detail_distant.rgb*(1.0-fd) * COLOR.rgb
		*pow((1.0-rim_detail_distant), distant_detail_factor)
		*distant_detail_strength
		;
	
	// color tweak.
	ALBEDO = vec3(
		pow(ALBEDO.r, color_power_r)*color_multiplier_r,
		pow(ALBEDO.g, color_power_g)*color_multiplier_g,
		pow(ALBEDO.b, color_power_b)*color_multiplier_b
	);
	
	// Dither.
	vec2 frag_coord = FRAGCOORD.xy;
	ALBEDO += interleaved_gradient_noise(frag_coord);
}
