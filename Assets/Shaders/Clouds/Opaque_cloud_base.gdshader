shader_type spatial;

uniform sampler2D depth_texture : source_color;
uniform mat4 inv_view_proj_matrix;

void fragment() {
    // Retrieve depth value of the current fragment
    float fragment_depth = DEPTH;

    // Transform screen space coordinates to view space
    vec4 screen_pos = vec4(SCREEN_UV.x * 2.0 - 1.0, SCREEN_UV.y * 2.0 - 1.0, fragment_depth * 2.0 - 1.0, 1.0);
    vec4 view_pos = inv_view_proj_matrix * screen_pos;
    view_pos /= view_pos.w;

    // Calculate the direction from the projector to the fragment in world space
    vec3 projector_position = vec3(0.0, 0.0, 0.0); // Set projector position
    vec3 fragment_pos = (VIEW_MATRIX * view_pos).xyz; // Transform view space to world space
    vec3 direction = normalize(fragment_pos - projector_position);

    // Check if the fragment is in front of the projector (visible)
    if (dot(direction, vec3(0.0, 0.0, -1.0)) > 0.0) {
        // Add your decal effect here, for example:
        ALBEDO = vec3(1.0, 1.0, 1.0); // Set the albedo to white for demonstration
    } else {
        discard; // Discard fragments behind the projector
    }
}
