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

uniform vec4 halo_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 corona_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);

uniform float strength_halo : hint_range(0.0, 1.0, 5e-4) = 0.005;
uniform float strength_corona : hint_range(0.0, 1.0, 5e-4) = 0.15;
uniform float strength_core : hint_range(0.0, 1.0, 5e-4) = 0.25;

uniform float exponent_halo : hint_range(0.0, 1.0, 5e-4) = 0.05;
uniform float exponent_corona : hint_range(0.0, 1.0, 5e-4) = 0.4;
uniform float exponent_core : hint_range(0.0, 1.0, 5e-4) = 0.6;

uniform float rim_exponent : hint_range(0.0, 1.0, 5e-4) = 0.1;
uniform float alpha_clip : hint_range(0.0, 1.0, 5e-4) = 1.0;

uniform sampler2D displacement_texture;
uniform float displacement_scale : hint_range(0.0, 1.0, 5e-4) = 0.1;
uniform float displacement_velocity : hint_range(0.0, 1.0, 5e-4) = 0.5;

uniform float dither_darken :  hint_range(0.5, 1.0, 5e-4) = 0.75;

const float dither_x = 172.7;
const float dither_y = 232.6;
const float dither_r = 105.5;
const float dither_g = 99.0;
const float dither_b = 110.0;

// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
uniform float Fcoef = 0.001;
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
	
	float displacement_x = 2.0*texture(displacement_texture, tex_position_x).r;
	float displacement_y = 2.0*texture(displacement_texture, tex_position_y).r;
	float displacement_z = 2.0*texture(displacement_texture, tex_position_z).r;
	
	VERTEX.z += displacement_x * displacement_scale * 0.05;
	VERTEX.z -= displacement_y * displacement_scale * 0.05;
	
	VERTEX.y += displacement_z * displacement_scale * 0.05;
	VERTEX.y -= displacement_x * displacement_scale * 0.05; 
	
	VERTEX.x += displacement_y * displacement_scale * 0.05;
	VERTEX.x -= displacement_z * displacement_scale * 0.05;
	
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;
}

void fragment()
{
	float dt = clamp(dot(NORMAL,VIEW), 1e-6, 1.0);
	float rim = clamp(pow(dt, rim_exponent*10.0), 1e-6, alpha_clip);
	float halo = clamp(pow(dt, exponent_halo*50.0)*strength_halo*100.0, 1e-6, 1.0);
	float corona = clamp(pow(dt, exponent_corona*50.0)*strength_corona*100.0, 1e-6, 1.0);
	float core = clamp(pow(dt, exponent_core*50.0)*strength_core*100.0, 1e-6, 1.0);
	
	ALBEDO = 
		+ halo*halo_color.rgb 
		+ corona*corona_color.rgb 
		+ core*core_color.rgb;
		
	ALBEDO *= rim;
	
	vec2 frag_coord = FRAGCOORD.xy;
	ALBEDO += interleaved_gradient_noise(frag_coord);
	
	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
