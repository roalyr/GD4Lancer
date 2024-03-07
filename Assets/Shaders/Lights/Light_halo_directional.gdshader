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
//uniform float scale_down_threshold :  hint_range(0.0, 1.0, 5e-4) = 0.0;
//uniform float scale_power:  hint_range(0.0, 1.0, 5e-4) = 1.0;
uniform float scale:  hint_range(0.0, 10.0, 5e-4) = 1.0;

uniform float a = 1.0;
uniform float b = 1.0;
uniform float c = 1.0;
uniform float d = 1.0;



uniform float dither_darken :  hint_range(0.5, 1.0, 5e-4) = 0.75;

const float dither_x = 172.7;
const float dither_y = 232.6;
const float dither_r = 105.5;
const float dither_g = 99.0;
const float dither_b = 110.0;

vec3 interleaved_gradient_noise(vec2 frag_coord) {
	vec3 dither = vec3(dot(vec2(dither_x, dither_y), frag_coord));
	dither.rgb = fract(dither.rgb / vec3(dither_r, dither_g, dither_b));
	return (dither.rgb - vec3(dither_darken)) / 255.0;
}

void vertex() {
	//VERTEX *= scale;
	
    // Transform the vertex position to clip space
    vec4 clip_position = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);

    // Calculate the distance from the vertex to the screen center
    float distance_to_center_x = clamp(length(pow(clip_position.x, d)), a, a*1e3);
    float distance_to_center_y = clamp(length(clip_position.y), a, a*1e3);
	
	float screen_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	
    // You can now use 'distance_to_center' as a measure of the vertex's distance to the screen center
	VERTEX *= 
		+ pow(clamp(c/distance_to_center_x, -c*0.5, c*0.5), b);
		//+ pow(clamp(d/distance_to_center_y, -c*0.5, c*0.5), 2.0) * screen_ratio;
}


void fragment()
{
	float dt = clamp(dot(NORMAL, VIEW), 1e-6, 1.0);
	float rim = clamp(pow(dt, rim_exponent * 50.0)*rim_strength, 1e-6, alpha_clip);
	ALBEDO = albedo.rgb;
	ALBEDO *= rim;
	vec2 frag_coord = FRAGCOORD.xy;
	ALBEDO += interleaved_gradient_noise(frag_coord);
}
