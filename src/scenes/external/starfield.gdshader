shader_type spatial;
render_mode unshaded;

uniform float grid_density = 10;
uniform float cutoff = 0.05;
uniform float star_bias = 1.0;
uniform bool debug = false;

float bias(float x, float bias) {
	return pow(x,bias);
}

float rand(float seed) {
	return fract(sin(dot(vec2(seed), vec2(12.9898, 4.1414))) * 43758.5453);
}

void fragment() {
        vec4 col = vec4(0.0);

        // Complex color calculation
		//col.xy = fract(SCREEN_UV*grid_density);
		vec4 world = INV_VIEW_MATRIX*vec4(normalize(VIEW),0.0);
		vec2 grid_coords = fract(-world.xy*grid_density);
		//grid_coords = world.xy;

		col = vec4(bias(rand(grid_coords.x + grid_coords.y),pow(10.0,star_bias)));


		if (debug) {
			ALBEDO.xy = grid_coords;
			ALPHA = 1.0;
		}
		else {
			ALBEDO = col.xyz;
        	ALPHA = col.a;
		}
}