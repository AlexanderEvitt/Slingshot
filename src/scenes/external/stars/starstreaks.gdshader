shader_type spatial;
render_mode unshaded;

uniform vec3 rotation_axis = vec3(1.0,0.0,0.0);
uniform float rotation_angle = 1.0;
uniform bool rotate = true;

varying float v;

float bias(float x, float bias) {
	return pow(x,bias);
}

float rand(float seed) {
	return fract(sin(dot(vec2(seed), vec2(12.9898, 4.1414))) * 43758.5453);
}

mat3 rotation_matrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float cosA = cos(angle);
    float sinA = sin(angle);
    float oneMinusCosA = 1.0 - cosA;

    vec3 row0 = vec3(
        cosA + axis.x * axis.x * oneMinusCosA,
        axis.x * axis.y * oneMinusCosA - axis.z * sinA,
        axis.x * axis.z * oneMinusCosA + axis.y * sinA
    );

    vec3 row1 = vec3(
        axis.y * axis.x * oneMinusCosA + axis.z * sinA,
        cosA + axis.y * axis.y * oneMinusCosA,
        axis.y * axis.z * oneMinusCosA - axis.x * sinA
    );

    vec3 row2 = vec3(
        axis.z * axis.x * oneMinusCosA - axis.y * sinA,
        axis.z * axis.y * oneMinusCosA + axis.x * sinA,
        cosA + axis.z * axis.z * oneMinusCosA
    );

    return mat3(row0, row1, row2);
}

void vertex() {
	// Rotate the even vertices
	v = float(VERTEX_ID);
	if (mod(v,2.0) == 0.0 ) {
		if (rotate) {
			VERTEX = rotation_matrix(rotation_axis, rotation_angle) * VERTEX;
		}
		v = v + 1.0;
	}
	COLOR = vec4(rand(v));
}

void fragment() {
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a; // Use vertex color alpha for transparency
}
