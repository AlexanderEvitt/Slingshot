shader_type spatial;
render_mode cull_front;

uniform sampler3D low_noise;
uniform sampler3D cell_noise;

uniform float bump = 1.0;

uniform sampler2D color_palette : repeat_disable;
uniform sampler2D roughness_palette : repeat_disable;

varying vec3 coord;

float multiply(float a, float b, float fac) {
	return fac*a + (1.0-fac*b);
}


float get_value(vec3 spot) {
	// Sample all the 3D noises
	float ln = texture(low_noise,0.3*coord).r;
	float mn = texture(low_noise,coord).r;
	float hn = texture(low_noise,5.0*coord).r;
	float cn = texture(cell_noise,coord).r;

	// Mix together results
	float multiply1 = mix(ln,ln*mn,0.2);
	float multiply2 = mix(multiply1,cn * multiply1,0.5);
	float multiply3 = mix(multiply2,hn * multiply2,0.5);
	multiply3 = clamp(multiply3,0.0,1.0);

	// Color ramp brightness
	float brightness = texture(color_palette,vec2(multiply3,0.0)).r;

	return brightness;
}

float get_height(vec3 spot) {
	// Sample all the 3D noises
	float ln = texture(low_noise,0.5*spot).r;
	float mn = texture(low_noise,spot).r;
	float hn = texture(low_noise,5.0*spot).r;
	float cn = texture(cell_noise,spot).r;

	// Mix together results
	float multiply1 = mix(ln,ln*mn,0.2);
	float multiply2 = mix(multiply1,cn * multiply1,1.0);

	// Return height
	float height = mix(multiply2,hn,0.1);
	return height;
}

vec3 calculate_normal(vec3 center, float delta, vec3 n) {
	// Calculate normal in latitude and longitude directions
	vec3 lon = cross(center, vec3(0.0,1.0,0.0));
	vec3 lat = cross(lon, center);
	lon = normalize(lon);
	lat = normalize(lat);

	// Calculate heights along deltas in those directions
	float height_pu = get_height(center + delta*lon);
	float height_mu = get_height(center - delta*lon);
	float height_pv = get_height(center + delta*lat);
	float height_mv = get_height(center - delta*lat);

	// Sobel operator
	float du = height_mu - height_pu;
	float dv = height_mv - height_pv;
	  n = normalize(du * lon + dv * lat + n * bump);
	return n;
}

void vertex() {
	coord = VERTEX;
}

void fragment() {
	// Map to result
	ALBEDO = vec3(get_value(coord));
	ROUGHNESS = texture(roughness_palette,vec2(get_value(coord),0.0)).r;

	// Mix my normal and generated normal
	NORMAL = mix(NORMAL, calculate_normal(coord, 0.0001, NORMAL), 0.5);
}
