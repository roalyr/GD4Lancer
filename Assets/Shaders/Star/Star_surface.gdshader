shader_type spatial;
render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	//use_debanding,

	// Blending and culling.
	blend_mix,
	cull_back,

	unshaded,
	//diffuse_lambert,
	specular_disabled,

	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 rim_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 surface_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform vec4 fade_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);

uniform float major_phase : hint_range(0, 3.14) = 1.1;

uniform float major_detail_intensity = 0.5;
uniform float detail_decay_distance = 1e12;
uniform float detail_decay_power : hint_range(0.0, 5.0, 5e-4) = 2.0;

uniform sampler2D major_detail_noise : hint_normal;

uniform float major_detail_scale : hint_range(1.0, 10.0, 1.0) = 1;

uniform float major_detail_flow = 0.01;

uniform float rim_strength = 1.0;
uniform float rim_exponent = 0.5;
uniform float rim_intensity = 0.3;

const float pi = 3.1415926535;
const vec3 WHITE = vec3(1.0,1.0,1.0);

// Add this before your vertex shader.
// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
const float Fcoef = 0.001;
varying float gl_Position_z;

// Add this to your vertex shader.
void vertex()
{
	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;
}



void fragment()
{
	vec2 p = texture(major_detail_noise, -UV*2.0*major_detail_scale).xy -TIME*major_detail_flow;
	float detail_major = sin(texture(major_detail_noise, p).r*pi+major_phase);
	float rim = clamp(pow(dot(NORMAL, VIEW), rim_exponent)*rim_strength, 1e-6, 1.0);

	float distance_factor = clamp(pow(length(VERTEX)/detail_decay_distance, detail_decay_power), 0.0, 1.0);

	ALBEDO = detail_major * WHITE * major_detail_intensity;

	ALBEDO += overlay_color.rgb * (1.0-distance_factor);
	ALBEDO *= surface_color.rgb * (1.0-distance_factor);
	ALBEDO += fade_color.rgb * distance_factor;
	ALBEDO += (1.0-rim) * rim_color.rgb * rim_intensity * (1.0-distance_factor);

	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}