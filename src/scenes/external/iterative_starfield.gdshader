shader_type sky;

uniform float grid_density = 10;
uniform float star_bias = 1.0;
uniform int num_stars = 100;
uniform float n = 1.0;
uniform float cutoff = 0.05;
uniform bool debug = false;

float bias(float x, float bias) {
	return pow(x,bias);
}

float rand(float seed) {
	return fract(sin(dot(vec2(seed), vec2(12.9898, 4.1414))) * 43758.5453);
}

void sky() {
	if (true) {
        vec4 col = vec4(0.0);

        // Complex color calculation
		vec2 grid_coords = fract(SKY_COORDS*grid_density);
		
		for (int i = 0; i < num_stars; i++)
		{
			float seed = rand(float(i));
			vec2 star_pos = vec2(rand(seed),rand(2.0*seed));
			if (length(grid_coords - star_pos) < cutoff) {
				col = vec4(bias(seed,pow(10.0,star_bias)));
			}
		}
		
		//col = vec4(bias(rand(grid_coords.x + grid_coords.y),pow(10.0,star_bias)));
        
		
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
