shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,

	// Blending and culling.
	blend_add,
	cull_back,

	unshaded,
	//diffuse_lambert,
	specular_disabled,

	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_never;

uniform vec4 albedo : source_color;


void fragment() {
	ALBEDO = albedo.rgb * COLOR.r * COLOR.r  ;
	DEPTH = 0.0;
}
