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
	float height_scale = 100.0;
	float texelSize = 1.0 / float(textureSize(noise1, 0).x);
	float t = texture(noise1, UV + vec2(texelSize * vec2(0.0, -1.0))).r * height_scale;
	float r = texture(noise1, UV + vec2(texelSize * vec2(1.0, 0.0))).r * height_scale;
	float l = texture(noise1, UV + vec2(texelSize * vec2(-1.0, 0.0))).r * height_scale;
	float b = texture(noise1, UV + vec2(texelSize * vec2(0.0, 1.0))).r * height_scale;

	NORMAL = -normalize(vec3(2.0 * (r - l), 2.0 * (b - t), -4.0));
}

void fragment() {
	ALBEDO = texture(main_texture, UV.xy).rgb;
}



//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
