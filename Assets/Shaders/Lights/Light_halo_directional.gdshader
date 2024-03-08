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
uniform float scale:  hint_range(0.0, 100.0, 5e-4) = 1.0;
uniform float beam_width :  hint_range(1.0, 1e4, 5e-4) = 1.0;
uniform float beam_power :  hint_range(1.0, 3.0, 5e-4) = 1.0;
uniform float beam_dist_factor :  hint_range(1.0, 1000.0, 5e-4) = 1.0;
uniform float beam_dist_power :  hint_range(0.0, 1.0, 5e-4) = 1.0;


uniform float scale_minimum : hint_range(0.0, 1.0, 5e-4) = 0.0;
uniform float fade = 1.0;
uniform float fade_power:  hint_range(0.0, 10.0, 5e-4) = 1.0;


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
	
	// Transform the vertex position to world space
    vec4 vertex_world_space = MODEL_MATRIX * vec4(VERTEX, 1.0);

    // Calculate the vector from the camera to the object origin in world space
    vec3 to_object_origin_world_space = vertex_world_space.xyz - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	float dist = length(to_object_origin_world_space);
	//VERTEX *= scale;

    // Transform the vertex position to clip space
    vec4 clip_position = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);

    // Calculate the distance from the vertex to the screen center
    //float distance_to_center_x = clamp(1.0 - length((clip_position.x*d)), 0.0, 1.0);
	
	//VERTEX *= clamp(scale_minimum*distance_to_center_x, 0.0, scale_minimum*0.5);
	float distance_to_center_y = length(clip_position.y);
	float distance_to_center_x = length(clip_position.x);
	float ratio = VIEWPORT_SIZE.x/VIEWPORT_SIZE.y;
	distance_to_center_x =  distance_to_center_x * ratio ;
	float magnification = scale*(pow(1.0 + (1.0/beam_width)*1e-3, -pow(distance_to_center_x, beam_power))+scale_minimum/scale);
	VERTEX *= magnification;
	VERTEX /= beam_dist_factor/ pow(dist, beam_dist_power);
	

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

}
