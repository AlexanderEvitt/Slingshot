shader_type spatial;

uniform sampler2D main_texture;
uniform sampler2D noise1;
uniform sampler2D noise2;
uniform sampler2D normal_noise;

uniform float intensity1;
uniform float intensity2;
uniform float intensity3;

uniform float crater_seed;
uniform float crater_wall_width;
uniform float crater_depth;
uniform int num_craters;
uniform float crater_bias;

float crater(float radius, vec2 relative_position) {
	if (length(relative_position) < radius) {
		return crater_depth;
	}
	else if (length(relative_position) - radius < crater_wall_width) {
		return (1.0 - crater_depth)*(length(relative_position) - radius)/crater_wall_width + crater_depth;
	}
	else {
		return 1.0;
	}
}

float bias(float x, float bias) {
	return pow(x,bias);
}

float rand(float seed) {
	return fract(sin(dot(vec2(seed), vec2(12.9898, 4.1414))) * 43758.5453);
}

void vertex() {
	VERTEX *= (1.0 + intensity1*texture(noise1, UV.xy).r) * (1.0 + intensity2*texture(noise2, UV.xy).r);

	// Add cratering
	for (int i = 0; i < num_craters; i++) {
		vec2 center = vec2(2.0*rand(crater_seed + float(i)),rand(crater_seed - float(i)));
		vec2 relative = vec2(2.0*UV.x, UV.y) - center;
		float size = 0.05*bias(rand(crater_seed + 2.0*float(i)),crater_bias);
		VERTEX *= (0.0 + crater(size, relative));
	}
	

	// Add normal maps
	//NORMAL = NORMAL + intensity3*texture(normal_noise, UV.xy).rgb;
	//NORMAL = texture(normal_noise, UV.xy).rgb;
	NORMAL = normalize(VERTEX);
}

void fragment() {
	ALBEDO = texture(main_texture, UV.xy).rgb;
}



//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
