shader_type spatial;

// Customizable properties
uniform vec4 outline_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform float outline_width : hint_range(0, 0.1) = 0.02;
uniform float outline_brightness : hint_range(0, 5) = 1.5;

void vertex() {
    // Expand the mesh along normals to create outline
    VERTEX += NORMAL * outline_width;
}

void fragment() {
    // Set the outline color and brightness
    ALBEDO = outline_color.rgb * outline_brightness;
    ALPHA = outline_color.a;

    // Make the outline always visible
    ALPHA_SCISSOR_THRESHOLD = 0.1;
    ALPHA_HASH_SCALE = 1.0;
}