shader_type spatial;

render_mode
	// Vertex or pixel shading (screen-large object can use vertex)
	vertex_lighting,

	// Blending and culling.
	blend_mix,
	cull_front,

	unshaded,
	diffuse_lambert,
	specular_disabled,

	// Additional flags just in case.
	ambient_light_disabled,
	depth_draw_opaque;

uniform vec4 albedo : source_color;
uniform vec4 albedo_glow_near : source_color;
uniform vec4 albedo_detail_distant : source_color;
uniform vec4 albedo_fog : source_color;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D distant_detail_noise;
uniform sampler2D normal_detail_minor_noise;

uniform float normal_detail_factor = 1.0;

uniform float distant_detail_phase = 1.0;
uniform float distant_detail_factor = 1.0;
uniform float distant_detail_strength = 1.0;


uniform float fade = 0;
uniform float fade_near = 0;
uniform float fade_fog = 0;

uniform float rim_strength = 1.0;
uniform float rim_exponent : hint_range(0.0, 10.0) = 1.0;



uniform float color_power_r = 1.0;
uniform float color_power_g = 1.0;
uniform float color_power_b = 1.0;
uniform float color_multiplier_r = 1.0;
uniform float color_multiplier_g = 1.0;
uniform float color_multiplier_b = 1.0;



uniform float dither_equal_strength = 0.5;
uniform float dither_noise_strength = 0.0;
uniform float dither_main_power = 1.0;
uniform float dither_threshold = 1.0;
uniform float dither_detail_contrast = 1.0;




uniform float dither_darken :  hint_range(0.5, 1.0, 5e-4) = 0.75;

const float dither_x = 172.7;
const float dither_y = 232.6;
const float dither_r = 105.5;
const float dither_g = 99.0;
const float dither_b = 110.0;


// Edit "Fcoef" to adjust for desirable view distance. Lesser number means further distance limit.
const float Fcoef = 0.001;
varying float gl_Position_z;

const mat4 bayer_array = mat4(
    vec4(0.0/16.0, 6.0/16.0, 2.0/16.0, 8.0/16.0),
    vec4(9.0/16.0, 4.0/16.0, 10.0/16.0, 14.0/16.0),
    vec4(3.0/16.0, 7.0/16.0, 1.0/16.0, 5.0/16.0),
    vec4(15.0/16.0, 11.0/16.0, 13.0/16.0, 12.0/16.0)
);

const mat4 bayer_array2 = mat4(
    vec4(0.0/16.0, 6.0/16.0, 2.0/16.0, 8.0/16.0),
    vec4(12.0/16.0, 4.0/16.0, 10.0/16.0, 14.0/16.0),
    vec4(3.0/16.0, 9.0/16.0, 1.0/16.0, 7.0/16.0),
    vec4(15.0/16.0, 11.0/16.0, 5.0/16.0, 13.0/16.0)
);




const float pi = 3.1415926535;

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness = 10.0;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale = vec3(100.0);
uniform vec3 uv1_offset;

vec3 interleaved_gradient_noise(vec2 frag_coord) {
	vec3 dither = vec3(dot(vec2(dither_x, dither_y), frag_coord));
	dither.rgb = fract(dither.rgb / vec3(dither_r, dither_g, dither_b));
	return (dither.rgb - vec3(dither_darken)) / 255.0;
}


void vertex() {
	vec3 normal = NORMAL;
	TANGENT = vec3(0.0,0.0,-1.0) * abs(normal.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(normal.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(normal.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale*1e-3 + uv1_offset*1e-2;
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);

	vec4 gl_Position = MODELVIEW_MATRIX*vec4(VERTEX, 1.0);
	gl_Position_z = gl_Position.z;

}




vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void fragment()
{
	// Get tangent, binormal and normal of the vertex.
	vec3 N = normalize(NORMAL);
	vec3 T = normalize(TANGENT);
	vec3 B = normalize(BINORMAL);

	// Get texture data.
	// Normal textures.
	vec4 nm_detail_minor_noise = triplanar_texture(normal_detail_minor_noise,uv1_power_normal,uv1_triplanar_pos);
		// Transform the RGB values of the normal map to the range [-1, 1].
	vec3 nm_detail_minor_noise_normalized = normalize(nm_detail_minor_noise.rgb * 2.0 - 1.0);
		// Transform normal map normal from tangent space to view space.
	vec3 nm_normal_detail_minor_view = normalize(mat3(T, B, N) * nm_detail_minor_noise_normalized);

	// Binary textures.
	float bm_distant_detail_noise = sin(triplanar_texture(distant_detail_noise,uv1_power_normal,uv1_triplanar_pos).r*pi+distant_detail_phase);

	// Calculate the dot product between the normal and view direction.
	float dt = clamp(dot(NORMAL, VIEW), 1e-6, 1.0);
	float dt_normal_detail_minor = clamp(dot(nm_normal_detail_minor_view, VIEW), 1e-6, 1.0);
	float dt_distant_detail = dt + dt * bm_distant_detail_noise * (1.0 - dt);

	// Attenuate the dot product.
	float rim_detail_distant = clamp(pow(dt_distant_detail, rim_exponent)*rim_strength, 1e-6, 1.0);
	float rim_normal_detail_minor = clamp(pow(dt_normal_detail_minor, rim_exponent)*rim_strength, 1e-6, 1.0);

	// Fade distances.
	float dist = length(VERTEX);
	float fd = 1.0-clamp(smoothstep(0.0, fade, dist), 1e-6, 1.0); // fades out
	float fd_discard = 1.0-clamp(smoothstep(0.0, fade_near, dist), 1e-6, 1.0); // fades out

	// Main color. Adjusted by noise maps.
	ALBEDO = albedo.rgb * COLOR.rgb
		*(1.0-rim_normal_detail_minor*fd*normal_detail_factor)
		;

	// Near field.
	ALBEDO += albedo_glow_near.rgb*fd
		;

	// Details field.
	ALBEDO += albedo_detail_distant.rgb*(1.0-fd) * COLOR.rgb
		*pow((1.0-rim_detail_distant), distant_detail_factor)
		*distant_detail_strength
		;

	// color tweak.
	ALBEDO = vec3(
		pow(ALBEDO.r, color_power_r)*color_multiplier_r,
		pow(ALBEDO.g, color_power_g)*color_multiplier_g,
		pow(ALBEDO.b, color_power_b)*color_multiplier_b
	);

	// Fog.
	ALBEDO += albedo_fog.rgb*clamp(smoothstep(0.0, fade_fog, length(VERTEX)), 1e-6, 1.0);



	// Dither colors.
	vec2 frag_coord = FRAGCOORD.xy;
	vec3 dither_color = interleaved_gradient_noise(frag_coord);
	ALBEDO += dither_color;

	// Dither alpha.
	// Equal distance dither
	float dither_equal = 0.0;
	float dither_equal2 = 0.0;
	float dither_equal3 = 0.0;
	if (mod(floor(FRAGCOORD.x+0.0), 3.0) == 0.0 && mod(floor(FRAGCOORD.y+2.0), 3.0) == 0.0) {
        dither_equal = 1.0; // Discard every Nth pixel
    }
	if (mod(floor(FRAGCOORD.x+1.0), 3.0) == 0.0 && mod(floor(FRAGCOORD.y+1.0), 3.0) == 0.0) {
        dither_equal2 = 1.0; // Discard every Nth pixel
    }
	if (mod(floor(FRAGCOORD.x+2.0), 3.0) == 0.0 && mod(floor(FRAGCOORD.y+0.0), 3.0) == 0.0) {
        dither_equal3 = 1.0; // Discard every Nth pixel
    }

	float bayer_value = bayer_array[int(FRAGCOORD.x) % 4][int(FRAGCOORD.y) % 4];

    float dither_noise_value = clamp(fract(sin(dot(SCREEN_UV + VIEW.xy*5e-2, vec2(12.9898, 5648.233))) * 43758.5453), 0.0, 1.0);

	float dither_main = pow((bayer_value), dither_main_power) + dither_noise_strength*dither_noise_value;
	float near_alpha = 1.0/fd_discard - dither_detail_contrast*rim_normal_detail_minor + dither_detail_contrast*rim_detail_distant;

	ALPHA_SCISSOR_THRESHOLD = dither_threshold + dither_main + dither_equal_strength*(dither_equal + dither_equal2 + dither_equal3);
	ALPHA = near_alpha;

	DEPTH = log2(max(1e-6, 1.0 -gl_Position_z)) * Fcoef;
}
