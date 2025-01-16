shader_type spatial;

uniform sampler2D main_texture;
uniform sampler2D noise1;
uniform sampler2D noise2;
uniform sampler2D normal_noise;

uniform float intensity1;
uniform float intensity2;
uniform float intensity3;

float crater(float radius, vec2 relative_position) {
	if (length(relative_position) < radius) {
		return 0.9;
	}
	else {
		return 1.0;
	}
}

void vertex() {
	VERTEX *= (1.0 + intensity1*texture(noise1, UV.xy).r) * (1.0 + intensity2*texture(noise2, UV.xy).r);

	// Add cratering
	vec2 center = vec2(0.5,0.5);
	vec2 relative = vec2(2.0*UV.x, UV.y) - center;
	VERTEX *= (0.0 + crater(0.05, relative));

	// Add normal maps
	NORMAL = NORMAL + intensity3*texture(normal_noise, UV.xy).rgb;
}

void fragment() {
	ALBEDO = texture(main_texture, UV.xy).rgb;
}



//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
