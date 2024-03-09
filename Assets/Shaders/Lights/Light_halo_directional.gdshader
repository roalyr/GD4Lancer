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

uniform vec4 albedo : source_color;
uniform float rim_strength :  hint_range(0.0, 1.0, 5e-4) = 0.1;
uniform float rim_exponent :  hint_range(0.0, 1.0, 5e-4) = 0.1;
uniform float alpha_clip :   hint_range(0.0, 1.0, 5e-4) = 1.0;

uniform float scale:  hint_range(0.0, 100.0, 5e-4) = 5.0;
uniform float beam_width_power :  hint_range(0.0, 2.0, 5e-4) = 0.5;
uniform float beam_width_focus :  hint_range(1.0, 10.0, 5e-4) = 2.0;
uniform float beam_dist_power :  hint_range(0.0, 1.0, 5e-4) = 0.5;

uniform float fade = 1.0;
uniform float fade_power:  hint_range(0.0, 10.0, 5e-4) = 1.0;


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

	float abs_scale = length(vec3(MODEL_MATRIX[0][0],MODEL_MATRIX[1][1],MODEL_MATRIX[2][2]));
	float dist = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z / abs_scale;

    // Transform the vertex position to clip space
    vec4 clip_position = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);
	float x_offset = clip_position.x / clip_position.w;

	float ratio = VIEWPORT_SIZE.x/VIEWPORT_SIZE.y;
	float distance_to_center_x = pow(length(x_offset), beam_width_power)*beam_width_focus;

	VERTEX *= pow(clamp(1.0/distance_to_center_x, 0.0, 2.0), 2.0);
	VERTEX *= pow(dist , beam_dist_power);
	VERTEX *= scale;


	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

}

void fragment()
{
	float dist = length(VERTEX)/scale;
	float fd = pow(clamp(smoothstep(0.0, fade, dist), 1e-6, 1.0), fade_power); // fades out

	float dt = clamp(dot(NORMAL, VIEW), 1e-6, 1.0);
	float rim = clamp(pow(dt, rim_exponent * 50.0)*rim_strength, 1e-6, alpha_clip);
	ALBEDO = albedo.rgb;
	ALBEDO *= rim;
	ALBEDO *= fd;
	vec2 frag_coord = FRAGCOORD.xy;
	ALBEDO += interleaved_gradient_noise(frag_coord);

	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
