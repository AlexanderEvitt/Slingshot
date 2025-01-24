shader_type sky;

uniform float grid_density = 10;
uniform float star_bias = 1.0;
uniform float n = 1.0;
uniform bool debug = false;

float bias(float x, float bias) {
	return pow(x,bias);
}

float rand(float seed) {
	return fract(sin(dot(vec2(seed), vec2(12.9898, 4.1414))) * 43758.5453);
}

void sky() {
	if (AT_CUBEMAP_PASS) {
        vec4 col = vec4(0.0);

        // Complex color calculation
		vec2 grid_coords = fract(SKY_COORDS*grid_density);
		//grid_coords = round(n*grid_coords)/n;
		
		col = vec4(bias(rand(grid_coords.x + grid_coords.y),pow(10.0,star_bias)));
        
		
		if (debug) {
			COLOR.xy = grid_coords;
			ALPHA = 1.0;
		}
		else {
			COLOR = col.xyz;
        	ALPHA = col.a;
		}
	} else {
        COLOR = texture(RADIANCE, EYEDIR).rgb;
    }
}
