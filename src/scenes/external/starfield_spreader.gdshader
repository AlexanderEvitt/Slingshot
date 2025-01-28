shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float star_bias = 1.0;
uniform float star_bloom = 1.0;

float bias(float x, float bias) {
	return pow(x,bias);
}

float rand(float seed) {
	return fract(sin(dot(vec2(seed), vec2(12.9898, 4.1414))) * 43758.5453);
}

void vertex() {
	float p1 = rand(float(VERTEX_ID))  - 0.5;
	float p2 = rand(float(VERTEX_ID + 1))  - 0.5;
	float p3 = rand(float(VERTEX_ID + 2))  - 0.5;
	VERTEX = (vec3(p1,p2,p3));
	
	VERTEX *= 1000.0/length(VERTEX);
}

void fragment() {
	float c = star_bloom*bias(rand(UV.x),star_bias);
	ALBEDO = vec3(c);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
