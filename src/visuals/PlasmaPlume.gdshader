
shader_type spatial;

render_mode blend_mix, unshaded, cull_back;

group_uniforms Basic_Effects;
uniform float model_height = 3.0;
uniform float dissolve_start : hint_range(0.0, 1.0) = 0.001;
uniform float dissolve_length : hint_range(0.0, 1.0) = 1.0;
uniform float gradient_bias : hint_range(0.1, 5.0) = 1.0;
uniform vec2 noise_direction = vec2(0.0, 1.0); // Direction of noise movement

group_uniforms Noise_Effects;
uniform float noise_speed = 1.0; // Speed of noise movement
uniform float noise_strength = 0.1; // Strength of the noise effect
uniform float stretch_factor = 0.6; // Factor to stretch the noise
uniform sampler2D noise_texture; // Noise texture

varying float vert_height;
varying vec2 v_uv;

group_uniforms Misc_Effects;
uniform vec3 _color : source_color;
uniform float power_factor = 1.0;
uniform float alpha_intensity_factor = 2.0;

group_uniforms Fresnel_Effects;
uniform float fresnel_factor = 1.0;
uniform float fresnel_amplification = 2.0; // Corrected typo
uniform float fresnel_power = 2.0;
uniform bool enable_fresnel = true;

vec3 neon(float value, vec3 color) {
    float ramp = clamp(value, 0.0, 1.0);
    vec3 output_color = vec3(0.0);
    ramp = ramp * ramp;
    output_color += pow(color, vec3(4.0)) * ramp;
    ramp = ramp * ramp;
    output_color += color * ramp;
    ramp = ramp * ramp;
    output_color += vec3(1.0) * ramp;
    return output_color;
}

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
    vert_height = (VERTEX.y + (model_height / 2.0)) / model_height;
    v_uv = UV;
}

void fragment() {
    float time = TIME * noise_speed;
    vec2 moving_uv = v_uv + noise_direction * time;
    vec2 stretched_uv = vec2(moving_uv.x, moving_uv.y * stretch_factor);
    float noise_value = texture(noise_texture, stretched_uv).r * noise_strength;

    float gradient_height = vert_height - dissolve_start;
    gradient_height *= 1.0 / dissolve_length;
    gradient_height = clamp(pow(gradient_height, gradient_bias) + noise_value, 0.0, 1.0);

    ALPHA = mix(1.0, 0.0, gradient_height);
    ALPHA = pow(ALPHA, power_factor);
    ALBEDO = neon(pow(ALPHA, power_factor), _color);

    ALPHA = pow(ALPHA, alpha_intensity_factor);

    if (enable_fresnel) {
        float fresnel_effect = 1.0 - fresnel(fresnel_factor, NORMAL, VIEW);
        fresnel_effect = pow(fresnel_effect * fresnel_amplification, fresnel_power);

        ALPHA *= fresnel_effect;
    }
}
