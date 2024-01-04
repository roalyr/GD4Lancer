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
uniform float scale_up_threshold :  hint_range(0.0, 100.0, 5e-4) = 10.0;
uniform float scale_down_threshold :  hint_range(0.0, 1.0, 5e-4) = 0.0;
uniform float scale_power:  hint_range(0.0, 1.0, 5e-4) = 1.0;


void vertex() {
	VERTEX *= scale_up_threshold;
	
    // get the vector from the object to the camera
    vec3 to_camera = normalize(INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz);

    // get the forward vector of the camera
    vec3 camera_forward = -normalize(INV_VIEW_MATRIX[2].xyz);

    // calculate the dot product between the two vectors
    float dot_product = dot(to_camera, camera_forward);

    // map the dot product from the range [-1, 1] to [0, 1]
	float t = 1.0;
	if (dot_product < 0.0){
		t = 0.0;
	} else {
		t = (dot_product + 1.0) / 2.0;
	}
    // calculate the new scale based on the mapped value
    float new_scale = pow(mix(scale_down_threshold, 1.0, t), 100.0 * scale_power);

    // apply the new scale to the vertex position
    VERTEX *= new_scale;
}

void fragment()
{
	float dt = clamp(dot(NORMAL, VIEW), 1e-6, 1.0);
	float rim = clamp(pow(dt, rim_exponent * 50.0)*rim_strength, 1e-6, alpha_clip);
	ALBEDO = albedo.rgb;
	ALBEDO *= rim;
}
