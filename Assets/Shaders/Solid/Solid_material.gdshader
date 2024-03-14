shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,

	// Blending and culling.
	blend_mix,
	cull_back,

	//unshaded,
	diffuse_lambert,
	specular_schlick_ggx,

	// Additional flags just in case.
	//ambient_light_disabled,
	depth_draw_opaque;

uniform sampler2D detail_map : hint_normal;
uniform sampler2D specular_map : hint_normal;

uniform vec4 albedo : source_color;
uniform vec4 albedo_specular : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 albedo_gloss : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec4 emission : source_color;
uniform float emission_strength : hint_range(0.0, 500.0, 0.1) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

uniform float albedo_exponent : hint_range(0.0, 50.0, 0.1) = 0.0;
uniform float specular_exponent : hint_range(0.0, 100.0, 0.1) = 5.0;
uniform float gloss_exponent : hint_range(0.0, 500.0, 0.1) = 500.0;
uniform float roughness_exponent : hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float roughness_sharpness : hint_range(0.0, 100.0, 0.1) = 100.0;

//uniform float specular_clip : hint_range(0,1) = 1.0;
//uniform float gloss_clip : hint_range(0,1) = 1.0;

uniform float scale = 1.0;
uniform float details_power = 1.0;
uniform float specular_power = 1.0;

uniform float dither_darken :  hint_range(0.5, 1.0, 5e-4) = 0.75;

const float dither_x = 172.7;
const float dither_y = 232.6;
const float dither_r = 105.5;
const float dither_g = 99.0;
const float dither_b = 110.0;

// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
const float Fcoef = 0.001;
varying float gl_Position_z;

vec3 interleaved_gradient_noise(vec2 frag_coord) {
	vec3 dither = vec3(dot(vec2(dither_x, dither_y), frag_coord));
	dither.rgb = fract(dither.rgb / vec3(dither_r, dither_g, dither_b));
	return (dither.rgb - vec3(dither_darken)) / 255.0;
}

void vertex() {
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

}

void fragment()
{

	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float albedo_rim = clamp(pow(dt, albedo_exponent), 0.0, 1.0);
	float specular_rim = clamp(pow(dt, specular_exponent), 0.0, 1.0);
	float gloss_rim = clamp(pow(dt, gloss_exponent), 0.0, 1.0);
	float roughness_rim = clamp(pow(dt, roughness_exponent), 0.0, 1.0);

	float details = texture(detail_map, UV*scale).r;
	float speculars = texture(specular_map, UV*scale).r;

	ALBEDO = albedo.rgb*albedo_rim*pow(details, details_power)
		+ albedo_specular.rgb*specular_rim*pow(speculars, specular_power)
		+ albedo_gloss.rgb*gloss_rim*pow(speculars, specular_power);
	ALBEDO *= COLOR.rgb ;
	EMISSION = emission.rgb * COLOR.rgb * emission_strength;
	ROUGHNESS =  1.0 - details*roughness * pow((1.0 - roughness_rim), roughness_sharpness);

	vec2 frag_coord = FRAGCOORD.xy;
	ALBEDO += interleaved_gradient_noise(frag_coord);

	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
