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
uniform vec4 albedo_outer : source_color;
uniform vec4 albedo_detail : source_color;
uniform vec4 albedo_detail_minor : source_color;

uniform float vertex_color = 1.0;


uniform sampler2D major_detail_noise;
uniform sampler2D minor_detail_noise;
uniform float major_detail_scale = 1.0;
uniform float major_detail_phase = 1.0;
uniform float major_factor = 1.0;

uniform float minor_detail_scale = 1.0;
uniform float minor_detail_phase = 1.0;
uniform float minor_factor = 1.0;

uniform float distance_fade_detail = 0;
uniform float distance_fade_detail_minor = 0.5;
uniform float distance_fade_outer_rim = 1;

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

vec3 interleaved_gradient_noise(vec2 frag_coord) {
	vec3 dither = vec3(dot(vec2(dither_x, dither_y), frag_coord));
	dither.rgb = fract(dither.rgb / vec3(dither_r, dither_g, dither_b));
	return (dither.rgb - vec3(dither_darken)) / 255.0;
}


void fragment()
{
	vec2 p = texture(major_detail_noise, -UV * 2.0 * major_detail_scale).yx;
	
	float detail_major = sin(texture(major_detail_noise, UV*major_detail_scale).r*pi+major_detail_phase);
	float detail_minor = sin(texture(minor_detail_noise, UV*minor_detail_scale).r*pi+minor_detail_phase);
	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float dt_detail = dt + dt * detail_major * (1.0 - dt);
	float dt_detail_minor = dt + dt * detail_minor * (1.0 - dt);
	float rim = clamp(pow(dt, rim_exponent)*rim_strength, 1e-6, 1.0);
	float rim_detail = clamp(dt_detail, 1e-6, 1.0);
	float rim_detail_minor = clamp(dt_detail_minor, 1e-6, 1.0);
	float dist = length(VERTEX);
	
	//ALBEDO = COLOR.rgb;
	ALBEDO = albedo.rgb*(rim);
	ALBEDO *= (1.0 - vertex_color) + COLOR.rgb * vertex_color;
	
	
	// Detail major + minor
	ALBEDO += clamp(pow((1.0-rim_detail), major_factor)*albedo_detail.rgb
			* (clamp(smoothstep(0.0, distance_fade_detail, dist), 1e-6, 1.0)), 0.0, 1.0);
	ALBEDO += clamp(pow((1.0 - rim_detail_minor), minor_factor)*albedo_detail_minor.rgb
			* (1.0 - clamp(smoothstep(0.0, distance_fade_detail_minor, dist), 1e-6, 1.0)), 0.0, 1.0);
	
	// Light ri, overlay
	ALBEDO += (1.0-rim)*albedo_outer.rgb*(1.0-clamp(smoothstep(0.0, distance_fade_outer_rim, dist), 1e-6, 1.0));
	
	
	ALBEDO = vec3(
		pow(ALBEDO.r, color_power_r)*color_multiplier_r,
		pow(ALBEDO.g, color_power_g)*color_multiplier_g,
		pow(ALBEDO.b, color_power_b)*color_multiplier_b
	);
	vec2 frag_coord = FRAGCOORD.xy;
	ALBEDO += interleaved_gradient_noise(frag_coord);


}
