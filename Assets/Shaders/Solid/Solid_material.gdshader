shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,
	shadows_disabled,

	// Blending and culling.
	blend_mix,
	cull_back,

	//unshaded,
	//diffuse_lambert,
	//specular_schlick_ggx,

	// Additional flags just in case.
	//ambient_light_disabled,
	depth_draw_opaque;

uniform sampler2D detail_map : hint_normal;
uniform vec4 albedo : source_color;
uniform vec4 emission : source_color;

uniform float emission_strength : hint_range(0.0, 10.0) = 1.0;

uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.5;

uniform float albedo_exponent = 0.0;
uniform float albedo_power = 1.0;



void fragment()
{
	float dt = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float albedo_rim = clamp(pow(dt, albedo_exponent), 0.0, 1.0);

	ALBEDO = albedo.rgb * COLOR.rgb ;
	EMISSION = emission.rgb * COLOR.rgb * emission_strength;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	//AO = 0.0;


}
