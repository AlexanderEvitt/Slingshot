shader_type spatial;
//render_mode world_vertex_coords;

uniform sampler2D lights_texture;
uniform vec4 emission_color : source_color = vec4(1.0);
uniform vec3 sun_dir = vec3(0.0,0.0,-1.0);


void fragment() {
	ALBEDO = texture(lights_texture, UV).rgb;
	ALPHA = texture(lights_texture, UV).r;
	
	EMISSION = texture(lights_texture, UV).r * emission_color.rgb;
	
	vec4 normal = INV_VIEW_MATRIX*vec4(NORMAL,0.0);
	if (dot(normal.xyz,sun_dir) > -0.1) {
		EMISSION = vec3(0.0);
		ALPHA = 0.0;
	}
}
