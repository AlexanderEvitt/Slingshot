shader_type spatial;

render_mode unshaded;

uniform sampler2D textured : source_color;
uniform vec3 colored : source_color;
uniform float fresnel_threshold = 0.8; // Adjust this value to set the Fresnel threshold
uniform float fresnel_power = 2.0;     // Adjust to control the sharpness of the Fresnel effect


void fragment() {
    vec2 uv = UV;
    vec4 color = texture(textured, uv);
    ALBEDO = color.rgb;
	
	    // Calculate the Fresnel effect
    vec3 view_dir = normalize(VIEW); // Direction from the fragment to the camera
    float fresnel = pow(1.0 - abs(dot(NORMAL, view_dir)), fresnel_power);

    // Check if Fresnel exceeds the threshold
    if (fresnel > fresnel_threshold) {
        ALBEDO = colored; // Set pixel to white
    } else {
        ALBEDO = color.rgb; // Use texture color
    }
}


//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
