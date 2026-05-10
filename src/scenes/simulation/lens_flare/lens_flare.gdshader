// TRANSLATED & MODIFIED FROM: https://www.shadertoy.com/view/4sX3Rs
// AND ALSO FROM https://www.shadertoy.com/view/dtKSDV

shader_type spatial;
render_mode unshaded, fog_disabled, blend_add;

const int MAX_SOURCES = 8;
uniform int source_count = 1;
uniform vec2 source_screen_uv[MAX_SOURCES];     // screen UV, y=0=top  (PackedVector2Array)
uniform float source_ndc_depth[MAX_SOURCES];    // reverse-Z depth; 0.0 = skip (PackedFloat32Array)
uniform float source_brightnesses[MAX_SOURCES]; // intrinsic brightness (PackedFloat32Array)
uniform vec3 source_colors[MAX_SOURCES];        // RGB tint per source (PackedVector3Array)

uniform vec3 tint = vec3(1.4, 1.2, 1.0);
uniform float spike_size = 1.0;         // diffraction spike scale for the sun (source 0)
uniform float source_spike_size = 1.0;  // diffraction spike scale for all other sources
uniform float blob_size = 128.0;        // blob falloff rate for the sun (higher = smaller)
uniform float source_blob_size = 128.0; // blob falloff rate for all other sources

uniform sampler2D depth_texture : hint_depth_texture;

// Bright central disc of a light source. Aspect-corrected so it's circular on screen.
// uv/pos in 0-1 screen UV space.
float blob(vec2 uv, vec2 pos, float aspect, float brightness, float scale)
{
	vec2 d_ac = vec2((uv.x - pos.x) * aspect, uv.y - pos.y);
	float d = length(d_ac);
	float f0 = brightness / (d * d * scale + 1.0); // scale controls size, brightness controls peak
	return f0;
}

// Chromatic ghost reflections along the source-to-center axis.
// Only meaningful for a dominant off-axis source like the sun — not engine plumes etc.
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
}

void fragment() {
	vec3 color = vec3(0.0);
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	// Aspect-corrected UV for this fragment, computed once and reused across all sources
	vec2 uv_ac = vec2((UV.x - 0.5) * aspect, UV.y - 0.5);
	bool any_on_screen = false;

	for (int i = 0; i < MAX_SOURCES; i++) {
		if (i >= source_count) break;

		// Screen position precomputed on CPU — skip sentinel (behind camera / off-screen)
		float ndc_depth = source_ndc_depth[i];
		if (ndc_depth == 0.0) continue;
		vec2 depth_uv = source_screen_uv[i];                        // y=0=top, matches depth texture
		vec2 screen_uv = vec2(depth_uv.x, 1.0 - depth_uv.y);       // y=0=bottom, matches mesh UV

		any_on_screen = true;

		// Occlusion: sun (source 0) uses a 5x5 soft kernel so it fades smoothly against
		// planet horizons; all other sources use a single sample — they're point sources
		// and the kernel costs 25x more per source per fragment.
		float occlusion;
		if (i == 0) {
			float visible = 0.0;
			for (int x = -2; x <= 2; x++) {
				for (int y = -2; y <= 2; y++) {
					float d = texture(depth_texture, depth_uv + vec2(float(x), float(y)) * 0.004).r;
					visible += step(d, ndc_depth);
				}
			}
			occlusion = visible * (1.0 / 25.0);
		} else {
			float d = texture(depth_texture, depth_uv).r;
			occlusion = step(d, ndc_depth);
		}
		if (occlusion <= 0.0) continue;

		vec3 src_color = vec3(0.0);
		vec3 src_tint = source_colors[i];

		// Blob and spikes — drawn for every source, tinted per-source
		float bsz = (i == 0) ? blob_size : source_blob_size;
		src_color += src_tint * vec3(blob(UV, screen_uv, aspect, source_brightnesses[i], bsz));
		vec2 src_ac = vec2((screen_uv.x - 0.5) * aspect, screen_uv.y - 0.5);
		float sz = (i == 0) ? spike_size : source_spike_size;
		src_color += src_tint * source_brightnesses[i] * vec3(spikes((uv_ac - src_ac) / sz));

		// Ghost reflections — first source (sun) only
		if (i == 0) {
			src_color += tint * cc(ghosts(UV, screen_uv), 0.5, 0.1);
		}

		color += src_color * occlusion;
	}

	if (!any_on_screen) discard;

	color = max(color, vec3(0.0));               // guard against negative ghost fringe values
	ALBEDO = color;
	ALPHA = max(color.r, max(color.g, color.b)); // any bright channel drives opacity
}
