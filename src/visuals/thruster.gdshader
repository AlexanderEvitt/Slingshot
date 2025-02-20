shader_type spatial;
render_mode unshaded, cull_disabled;


uniform sampler2D textured : source_color;

group_uniforms Fresnel_Effects;
uniform float fresnel_factor = 1.0;
uniform float fresnel_amplification = 2.0;
uniform float fresnel_power = 2.0;

uniform sampler2D noise_texture;


float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	float along = UV.y;
	VERTEX.xz *= (1.0 + texture(noise_texture, UV + 1.0*vec2(TIME)).x*along);
}

void fragment() {
	float along = UV.y;
	vec4 color = texture(textured, UV + vec2(0.01f,0.01f));
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA *= (0.5 + texture(noise_texture, UV + vec2(TIME)).x*along);

	float fresnel_effect = 1.0 - fresnel(fresnel_factor, NORMAL, VIEW);
    fresnel_effect = pow(fresnel_effect * fresnel_amplification, fresnel_power);

    ALPHA *= fresnel_effect;
}
