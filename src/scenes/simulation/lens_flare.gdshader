// TRANSLATED & MODIFIED FROM: https://www.shadertoy.com/view/4sX3Rs
// AND ALSO FROM https://www.shadertoy.com/view/dtKSDV

shader_type spatial;
render_mode unshaded, fog_disabled;

uniform vec3 sun_world_position = vec3(0.0,0.0,-1000000.0);
uniform vec3 tint = vec3(1.4,1.2,1.0);

uniform float sun_size = 0.1;
uniform float spike_size = 1.0;

uniform sampler2D depth_texture : hint_depth_texture;

varying vec2 sun_screen_uv;  // Sun's position in visual UV space (Y-flipped), used for blob/spikes/ghosts
varying vec2 sun_depth_uv;   // Sun's position in depth texture UV space (no Y-flip)
varying float sun_ndc_depth; // Sun's raw NDC depth, compared directly against the depth texture

// Bright central disc of a light source. Aspect-corrected so it's circular on screen.
// uv/pos in 0-1 screen UV space.
float blob(vec2 uv, vec2 pos, float aspect)
{
	vec2 d_ac = vec2((uv.x - pos.x) * aspect, uv.y - pos.y);
	float dist = pow(length(uv - pos), 0.1);
	float f0 = sun_size / (length(d_ac) * 16.0 + 1.0);
	return f0 + f0 * (dist * 0.1 + 0.8);
}

// Chromatic ghost reflections along the sun-to-center axis. Sun only — not appropriate
// for engine plumes etc. since ghosts only make sense for a dominant off-axis light source.
// uv/pos in 0-1 screen UV space.
vec3 ghosts(vec2 uv, vec2 pos)
{
	vec2 uvd = uv * length(uv); // distorted UV, pulls reflections toward screen edges

	// Three sets of ghosts, each split across RGB channels to simulate lens dispersion
	float f2  = max(1.0/(1.0+32.0*pow(length(uvd+0.800*pos),2.0)),.0)*0.25;
	float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.850*pos),2.0)),.0)*0.23;
	float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.900*pos),2.0)),.0)*0.21;

	vec2 uvx = mix(uv, uvd, -0.5);

	float f4  = max(0.01-pow(length(uvx+0.400*pos),2.4),.0)*6.0;
	float f42 = max(0.01-pow(length(uvx+0.450*pos),2.4),.0)*5.0;
	float f43 = max(0.01-pow(length(uvx+0.500*pos),2.4),.0)*3.0;

	uvx = mix(uv, uvd, -0.4);

	float f5  = max(0.01-pow(length(uvx+0.2*pos),5.5),.0)*2.0;
	float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),.0)*2.0;
	float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),.0)*2.0;

	uvx = mix(uv, uvd, -0.5);

	float f6  = max(0.01-pow(length(uvx-0.300*pos),1.6),.0)*6.0;
	float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
	float f63 = max(0.01-pow(length(uvx-0.350*pos),1.6),.0)*5.0;

	vec3 c = vec3(0.0);
	c.r += f2+f4+f5+f6; c.g += f22+f42+f52+f62; c.b += f23+f43+f53+f63;
	return c * 1.3 - vec3(length(uvd) * 0.05);
}

vec3 cc(vec3 color, float factor, float factor2) // color modifier
{
	float w = color.x + color.y + color.z;
	return mix(color, vec3(w) * factor, w * factor2);
}

const float R32 = 0.8660254; // sin(60°), used to build 60° and 120° rotation matrices
const mat2 rot1 = mat2(vec2(0.5, -R32), vec2(R32, 0.5));  // rotate 60°
const mat2 rot2 = mat2(vec2(0.5,  R32), vec2(-R32, 0.5)); // rotate 120°

// A single spike arm: very narrow bright line along one axis
float spike(vec2 d) {
	vec2 s = abs(d) * vec2(8.0, 1.0);
	return 64.0 * (dot(s, s) + sqrt(s.x) + s.y);
}

// Three overlapping spike arms at 0°, 60°, and 120° — produces a 6-pointed diffraction star.
// Falloff shrinks the effect beyond distance 1 from the source.
float spikes(vec2 p) {
	float falloff = clamp(1.0 - length(p), 0.0, 1.0);
	return falloff*0.3/spike(p.yx) + 1.0/spike(p)
	     + 1.0/spike(rot1*p) + 1.0/spike(rot2*p);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0); // Pin quad to clip space so it covers the full screen

	vec4 clip_space_pos = PROJECTION_MATRIX * VIEW_MATRIX * vec4(sun_world_position, 1.0);

	if (clip_space_pos.w < 0.0) {
		sun_screen_uv = vec2(-10.0, -10.0);
		sun_depth_uv  = vec2(-10.0, -10.0);
		sun_ndc_depth = 0.0;
	} else {
		vec3 ndc_pos = clip_space_pos.xyz / clip_space_pos.w;
		sun_depth_uv  = ndc_pos.xy * 0.5 + 0.5;                     // depth texture space (no Y-flip)
		sun_screen_uv = vec2(sun_depth_uv.x, 1.0 - sun_depth_uv.y); // visual UV space (Y-flipped)
		sun_ndc_depth = clamp(ndc_pos.z, 0.0, 1.0); // clamp so beyond-far-plane doesn't read as fully occluded
	}
}

void fragment() {
	vec3 color = vec3(0.0);

	// Soft occlusion: sample a 5x5 kernel around the sun's screen position.
	// Raw NDC depth comparison avoids precision loss from reconstructing view-space Z.
	const int R = 2;
	const float STEP = 0.004;
	float visible = 0.0;
	for (int x = -R; x <= R; x++) {
		for (int y = -R; y <= R; y++) {
			vec2 s_uv = sun_depth_uv + vec2(float(x), float(y)) * STEP;
			float d = texture(depth_texture, s_uv).r;
			visible += step(d, sun_ndc_depth); // 1 if scene depth <= sun depth (reverse Z: near=1, far=0)
		}
	}
	float occlusion_factor = visible * (1.0 / 25.0); // 0 = fully occluded, 1 = fully visible

	if (occlusion_factor > 0.0) {
		float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

		// Blob and spikes — drawn for all light sources
		color += tint * vec3(blob(UV, sun_screen_uv, aspect));
		vec2 uv_ac  = vec2((UV.x           - 0.5) * aspect, UV.y           - 0.5);
		vec2 sun_ac = vec2((sun_screen_uv.x - 0.5) * aspect, sun_screen_uv.y - 0.5);
		color += vec3(spikes((uv_ac - sun_ac) / spike_size));

		// Ghost reflections — sun only
		color += tint * cc(ghosts(UV, sun_screen_uv), 0.5, 0.1);

		color *= occlusion_factor;
	}

	//float d = texture(depth_texture, SCREEN_UV).r; ALBEDO = vec3(d); ALPHA = 1.0; return;
	ALBEDO = color;
	ALPHA = color.r;

	float fuzz = 0.05;
	if (sun_screen_uv.x < -fuzz || sun_screen_uv.x > 1.0 + fuzz || sun_screen_uv.y < -fuzz || sun_screen_uv.y > 1.0 + fuzz) {
		discard;
	}
}
