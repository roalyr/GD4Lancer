shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,

	// Blending and culling.
	blend_mix,
	cull_back,

	//unshaded,
	diffuse_lambert,
	specular_disabled,

	// Additional flags just in case.
	//ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float specular : hint_range(0,1) = 0.5;
uniform float metallic : hint_range(0,1) = 0.0;
uniform float roughness : hint_range(0,1) = 0.5;
uniform float normal_depth : hint_range(-1,1) = 1.0;
uniform float alpha : hint_range(0,1) = 1.0;

uniform sampler2D texture_alpha : hint_normal;
uniform sampler2D texture_specular : hint_normal;
uniform sampler2D texture_roughness : hint_normal;
uniform sampler2D texture_normal_depth : hint_normal;
uniform sampler2D texture_diffuse : hint_normal;
uniform sampler2D texture_normal : hint_normal;

void fragment()
{
	ALBEDO = albedo.rgb*COLOR.rgb*texture(texture_diffuse, UV).r;
	METALLIC = metallic;
	EMISSION = emission.rgb*COLOR.rgb;
	SPECULAR = specular*texture(texture_specular, UV).r;
	ROUGHNESS = roughness*texture(texture_roughness, UV).r;

	ALPHA = alpha*texture(texture_alpha, UV).r;

	//NORMALMAP = texture(texture_normal, UV).rgb;
	//NORMALMAP_DEPTH = normal_depth;

	// See cloud base for pseudo-normals
}
