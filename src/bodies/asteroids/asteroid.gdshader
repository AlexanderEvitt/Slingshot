shader_type spatial;
render_mode cull_front;

uniform sampler2D main_texture;
uniform sampler2D noise1;
uniform sampler2D noise2;
uniform sampler2D norm_noise;

uniform float intensity1;
uniform float intensity2;
uniform float intensity3;

uniform float crater_seed;
uniform float crater_wall_width;
uniform float crater_depth;
uniform int num_craters;
uniform float crater_bias;

uniform float pole_margin;

uniform sampler2D palette;

varying vec3 vert;

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

vec3 getHeight(vec2 uv) {
	float theta = uv.x * 2.0 * PI;
	float phi = uv.y * PI;
	vec3 x = vec3(cos(theta)*sin(phi), sin(theta)*sin(phi), cos(phi));
	vec3 y = x*(1.0 + intensity1*texture(noise1, uv.xy).r) * (1.0 + intensity2*texture(noise2, uv.xy).r);

	// Add cratering
	for (int i = 0; i < num_craters; i++) {
		vec2 center = vec2(2.0*rand(crater_seed + float(i)),rand(crater_seed - float(i)));
		vec2 relative = vec2(2.0*uv.x, uv.y) - center;
		float size = 0.05*bias(rand(crater_seed + 2.0*float(i)),crater_bias);
		y *= (0.0 + crater(size, relative));
	}

	// blend to unit length around poles
	if (uv.y > 1.0 - pole_margin) {
		float combine = (1.0/pole_margin)*(uv.y - (1.0 - pole_margin));
		vec3 pole = x*(1.0 + intensity1*texture(noise1, vec2(0,1)).r) * (1.0 + intensity2*texture(noise2, vec2(0,1)).r);
		y = combine*pole + (1.0-combine)*y;
	}

	if (uv.y < pole_margin) {
		float combine = 1.0 - (1.0/pole_margin)*(uv.y);
		vec3 pole = x*(1.0 + intensity1*texture(noise1, vec2(0,1)).r) * (1.0 + intensity2*texture(noise2, vec2(0,1)).r);
		y = combine*pole + (1.0-combine)*y;
	}

	return y;
}

void vertex() {
	vert = VERTEX;
}

void fragment() {
	float height = length(vert)/2.2;
	ALBEDO = texture(palette,vec2(height,0)).rgb;

	NORMAL += 0.1*texture(norm_noise,UV).xyz;
}
