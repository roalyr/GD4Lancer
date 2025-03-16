shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness : hint_range(0.01, 1.0) = 0.2;
uniform float specular_intensity : hint_range(0.0, 20.0) = 0.5;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.25;
uniform float posterization_levels = 4.0;

// Bayer matrix (4x4).
const float bayer_matrix[16] = {
	 0.0,  8.0,  2.0, 10.0,
	12.0,  4.0, 14.0,  6.0,
	 3.0, 11.0,  1.0,  9.0,
	15.0,  7.0, 13.0,  5.0
};

// Helper function for Bayer matrix lookup
float bayer4x4(int x, int y) {
	int index = y * 4 + x;
	return bayer_matrix[index] / 16.0;
}

// GGX/Trowbridge-Reitz Normal Distribution Function (NDF)
float ndf_ggx(float NoH, float roughness_val) {
    float a2 = pow(roughness_val, 4.0);
    float d = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * d * d);
}

// Schlick-Beckmann Geometric Shadowing (Visibility)
float geometry_schlick_beckmann(float NoV, float NoL, float roughness_val) {
    float k = pow(roughness_val + 1.0, 2.0) / 8.0;
    float vis_n = NoL / (NoL * (1.0 - k) + k);
    float vis_v = NoV / (NoV * (1.0 - k) + k);
    return vis_n * vis_v;
}

// Fresnel (Schlick approximation)
vec3 fresnel_schlick(float cos_theta, vec3 f0) {
    return f0 + (vec3(1.0) - f0) * pow(1.0 - cos_theta, 5.0);
}

// Lambertian Diffuse BRDF (for comparison and potential blending)
vec3 diffuse_lambertian(vec3 albedo_val) {
    return albedo_val / PI;
}

// Burley (Disney) Diffuse BRDF
vec3 diffuse_burley(vec3 albedo_val, float roughness_val, float NoV, float NoL, float LoH) {
	float f90 = 0.5 + 2.0 * roughness_val * pow(LoH, 2.0);
	float lightScatter = 1.0 + (f90 - 1.0) * pow(1.0 - NoL, 5.0);
	float viewScatter  = 1.0 + (f90 - 1.0) * pow(1.0 - NoV, 5.0);
	return (albedo_val / PI) * lightScatter * viewScatter;
}

// Toon Diffuse BRDF
vec3 diffuse_toon(vec3 albedo_val, float NoL, float levels) {
    float intensity = floor(NoL * levels) / levels; // Quantize the dot product
    return albedo_val * intensity;
}

// Posterization function
vec3 posterize(vec3 color, float levels) {
    return floor(color * levels) / levels;
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
}

void light() {
	// --- Dithering Setup (using FRAGCOORD) ---
	int x = int(mod(FRAGCOORD.x, 4.0));
	int y = int(mod(FRAGCOORD.y, 4.0));
	float threshold = bayer4x4(x, y);

	// --- PBR Calculations ---
	vec3 n = NORMAL;
	vec3 l = LIGHT;
	vec3 v = VIEW;
	vec3 h = normalize(v + l);
	float NoL = max(dot(n, l), 0.0);
	float NoV = max(dot(n, v), 0.0);
	float NoH = max(dot(n, h), 0.0);
	float LoH = max(dot(l, h), 0.0);

    // Dithered NoL
    float dithered_NoL = mix(NoL, step(threshold, NoL) * NoL, dither_strength);


	// --- Diffuse ---
    // Choose *one* of these diffuse models.  Comment out the others.
	//vec3 diffuse_brdf = diffuse_lambertian(ALBEDO);  // Lambertian
	//vec3 diffuse_brdf = diffuse_burley(ALBEDO, ROUGHNESS, NoV, dithered_NoL, LoH); // Burley
	vec3 diffuse_brdf = diffuse_toon(ALBEDO, dithered_NoL, posterization_levels);  // Toon (quantized)

	vec3 diffuse_light = diffuse_brdf * dithered_NoL; // Apply dithering


	// --- Specular ---
	vec3 f0 = vec3(0.04); // For non-metals
	vec3 fresnel = fresnel_schlick(max(0.0, dot(h, v)), f0);
	fresnel *= specular_intensity;

	float distribution = ndf_ggx(NoH, ROUGHNESS);
	float visibility = geometry_schlick_beckmann(NoV, dithered_NoL, ROUGHNESS);
	vec3 specular_brdf = (distribution * visibility * fresnel);
	vec3 specular_light = specular_brdf * dithered_NoL; // Apply dithering

	// Combine, apply attenuation and light color, and posterize.
	vec3 combined_light = (diffuse_light + specular_light) * ATTENUATION * LIGHT_COLOR;
	combined_light = posterize(combined_light, posterization_levels);

	// Output
	DIFFUSE_LIGHT += combined_light;
}