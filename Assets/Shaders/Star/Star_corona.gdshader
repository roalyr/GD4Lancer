shader_type spatial;
render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,

	// Blending and culling.
	blend_add,
	cull_front,

	unshaded,
	//diffuse_lambert,
	specular_disabled,

	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 corona_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform float strength_corona  = 0.15;
uniform float exponent_corona = 0.4;
uniform float exponent_corona_rim = 0.4;
uniform float corona_floor_power = 5.0;
uniform float corona_floor : hint_range(0.0, 1e2, 5e-4) = 1.5;

uniform sampler2D displacement_texture;
uniform float displacement_power : hint_range(-0.2, 0.2, 5e-4) = 0.1;
uniform float displacement_scale_xz : hint_range(0.0, 2.0, 5e-4) = 1.0;
uniform float displacement_scale_y : hint_range(0.0, 2.0, 5e-4) = 1.0;
uniform float displacement_velocity : hint_range(0.0, 2.0, 5e-4) = 0.5;

uniform float dither_darken :  hint_range(0.5, 1.0, 5e-4) = 0.75;

const float dither_x = 172.7;
const float dither_y = 232.6;
const float dither_r = 105.5;
const float dither_g = 99.0;
const float dither_b = 110.0;

varying float noise_val;

// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
const float Fcoef = 0.001;
varying float gl_Position_z;

vec3 interleaved_gradient_noise(vec2 frag_coord) {
	vec3 dither = vec3(dot(vec2(dither_x, dither_y), frag_coord));
	dither.rgb = fract(dither.rgb / vec3(dither_r, dither_g, dither_b));
	return (dither.rgb - vec3(dither_darken)) / 255.0;
}

void vertex() {
	vec2 tex_position_x = VERTEX.yz - TIME*displacement_velocity*0.1;
	vec2 tex_position_y = VERTEX.xz + TIME*displacement_velocity*0.1;
	vec2 tex_position_z = VERTEX.xy - TIME*displacement_velocity*0.1;
	vec2 tex_position_uv = UV - TIME*displacement_velocity*0.1;

	float displacement_x = 2.0*texture(displacement_texture, tex_position_x).r;
	float displacement_y = 2.0*texture(displacement_texture, tex_position_y).r;
	float displacement_z = 2.0*texture(displacement_texture, tex_position_z).r;
	float displacement_uv = 2.0*texture(displacement_texture, tex_position_uv).r;

	noise_val = pow( displacement_z * displacement_x * displacement_y, displacement_power);
	VERTEX *= noise_val;



	VERTEX.xz *= displacement_scale_xz;
	VERTEX.y *= displacement_scale_y;

	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;
}

void fragment()
{
	float dt = clamp(dot(NORMAL,VIEW), 1e-6, 1.0);
	float corona = clamp(pow(dt, exp(exponent_corona))*strength_corona, 1e-6, 1.0);

	ALBEDO =  pow(corona, exponent_corona_rim)*corona_color.rgb;
	ALBEDO *= corona_floor - pow(noise_val, corona_floor_power);

	vec2 frag_coord = FRAGCOORD.xy;
	ALBEDO += interleaved_gradient_noise(frag_coord);

	//DEPTH = 1.0 - log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
