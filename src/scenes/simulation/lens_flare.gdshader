// TRANSLATED & MODIFIED FROM: https://www.shadertoy.com/view/4sX3Rs
// AND ALSO FROM https://www.shadertoy.com/view/dtKSDV

shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;

uniform vec3 sun_world_position = vec3(0.0,0.0,-1000000.0);
uniform bool show_sun = false;
uniform vec3 tint = vec3(1.4,1.2,1.0);
uniform sampler2D noise_texture;

uniform float sun_size = 0.1;
uniform float spike_size = 1.0;

uniform sampler2D depth_texture : hint_depth_texture; // Scene depth buffer
uniform sampler2D screen_texture : hint_screen_texture;

varying vec2 sun_screen_uv;  // Sun's position in visual UV space (Y-flipped), used for blob/spikes
varying vec2 sun_depth_uv;   // Sun's position in depth texture UV space (no Y-flip)
varying float sun_ndc_depth; // Sun's raw NDC depth, compared directly against the depth texture

// Noise helpers — index into noise texture by coordinate, used to break up the flare shape
float noise_float(float t, vec2 texResolution)
{
	return texture(noise_texture,vec2(t,0.0)/texResolution).x;
}
float noise_vec2(vec2 t, vec2 texResolution)
{
	return texture(noise_texture,t/texResolution).x;
}

// Produces the main glare blob and secondary lens reflections along the sun-to-center axis.
// uv: current fragment position (0-1), pos: sun screen position (0-1)
// aspect: viewport width/height, used only for the sun blob so it stays circular
vec3 lensflare(vec2 uv, vec2 pos, vec2 texResolution, float aspect)
{
	vec2 main = uv-pos;
	vec2 uvd = uv*(length(uv)); // distorted UV, pulls reflections toward screen edges

	float ang = atan(main.x,main.y);
	float dist = length(main);
	dist = pow(dist,0.1);

	float n = noise_vec2(vec2(ang*16.0,dist*32.0), texResolution);

	// Central sun blob — aspect-corrected so the blob is circular, not elliptical.
	// Ghost reflections below use raw UV so they fill the screen correctly.
	vec2 d_ac = vec2((uv.x - pos.x) * aspect, uv.y - pos.y);
	float ang_ac = atan(d_ac.x, d_ac.y);
	float f0 = sun_size*1.0/(length(d_ac)*16.0+1.0);
	f0 = f0 + f0*(sin(noise_float(sin(ang_ac*2.+pos.x)*4.0 - cos(ang_ac*3.+pos.y), texResolution)*16.)*.1 + dist*.1 + .8);

	float f1 = max(0.01-pow(length(uv+1.2*pos),1.9),.0)*7.0;

	// Chromatic ghost reflections — offset slightly per channel to simulate lens dispersion
	float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*00.25;
	float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*00.23;
	float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*00.21;

	vec2 uvx = mix(uv,uvd,-0.5);

	float f4 = max(0.01-pow(length(uvx+0.4*pos),2.4),.0)*6.0;
	float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*5.0;
	float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*3.0;

	uvx = mix(uv,uvd,-.4);

	float f5 = max(0.01-pow(length(uvx+0.2*pos),5.5),.0)*2.0;
	float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),.0)*2.0;
	float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),.0)*2.0;

	uvx = mix(uv,uvd,-0.5);

	float f6 = max(0.01-pow(length(uvx-0.3*pos),1.6),.0)*6.0;
	float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
	float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6),.0)*5.0;

	vec3 c = vec3(.0);

	// Assign ghost layers to separate RGB channels for chromatic aberration
	c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
	c = c*1.3 - vec3(length(uvd)*.05);

	// Do not need an artificial sun
	c+=vec3(f0);

	return c;
}

vec3 cc(vec3 color, float factor,float factor2) // color modifier
{
	float w = color.x+color.y+color.z;
	return mix(color,vec3(w)*factor,w*factor2);
}

const float R32 = 0.8660254; // sin(60°), used to build 60° and 120° rotation matrices
const mat2 rot1 = mat2(vec2(0.5, -R32), vec2(R32, 0.5));  // rotate 60°
const mat2 rot2 = mat2(vec2(0.5, R32), vec2(-R32, 0.5));  // rotate 120°

// A single spike arm: very narrow bright line along one axis
float spike(vec2 d) {
    vec2 s = abs(d) * vec2(8,1);
    return 64.*(dot(s,s) + sqrt(s.x) + s.y);
}

// Three overlapping spike arms at 0°, 60°, and 120° — produces a 6-pointed diffraction star.
// Falloff shrinks the effect beyond distance 1 from the sun.
float spikes(vec2 p) {
    float d = length(p);
    float falloff = 1.0 - d;
	falloff = clamp(falloff,0.0,1.0);

    return falloff*0.3/spike(p.yx) + 1.0/spike(p)
    + 1.0/spike(rot1*p) + 1.0/spike(rot2*p);

}

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0); // Pin quad to clip space so it covers the full screen

    // Project sun world position into screen UV space for use in fragment
    vec4 clip_space_pos = PROJECTION_MATRIX * VIEW_MATRIX * vec4(sun_world_position, 1.0);

    // If the sun is behind the camera, move it off-screen
    if (clip_space_pos.w < 0.0) {
        sun_screen_uv = vec2(-10.0, -10.0);
        sun_depth_uv  = vec2(-10.0, -10.0);
        sun_ndc_depth = 0.0;
    } else {
        vec3 ndc_pos = clip_space_pos.xyz / clip_space_pos.w; // Normalize to NDC
        sun_depth_uv  = ndc_pos.xy * 0.5 + 0.5;                // depth texture space (no Y-flip)
        sun_screen_uv = vec2(sun_depth_uv.x, 1.0 - sun_depth_uv.y); // visual UV space (Y-flipped)
        sun_ndc_depth = clamp(ndc_pos.z, 0.0, 1.0); // Clamp so beyond-far-plane doesn't read as fully occluded
    }
}


void fragment() {
    vec2 texResolution = 1.0 / VIEWPORT_SIZE;

    vec3 color = vec3(0.0);

    // Soft occlusion: sample a kernel of depth values around the sun's screen position.
    // Comparing raw NDC depths avoids the precision loss of reconstructing view-space Z,
    // and keeps both values in the same space as the depth texture stores them.
    const int R = 2;
    const float STEP = 0.004;
    float visible = 0.0;
    float total = 0.0;
    for (int x = -R; x <= R; x++) {
        for (int y = -R; y <= R; y++) {
            vec2 s_uv = sun_depth_uv + vec2(float(x), float(y)) * STEP;
            float d = texture(depth_texture, s_uv).r;
            visible += step(d, sun_ndc_depth); // 1 if scene depth <= sun depth (reverse Z: near=1, far=0)
            total += 1.0;
        }
    }
    float occlusion_factor = visible / total; // 0 = fully occluded, 1 = fully visible

    if (occlusion_factor > 0.0) {
        float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;

        // Lens flare ghosts use 0-1 UV so reflections fill the screen correctly.
        // Aspect ratio is passed in for the sun blob only (corrected inside lensflare).
        color += tint * lensflare(UV, sun_screen_uv, texResolution, aspect);
        color -= noise_vec2(FRAGCOORD.xy, texResolution) * 0.015; // subtle grain
        color = cc(color, 0.5, 0.1);

        // Diffraction spikes use aspect-corrected centered space so arms are symmetric.
        vec2 uv_ac  = vec2((UV.x           - 0.5) * aspect, UV.y           - 0.5);
        vec2 sun_ac = vec2((sun_screen_uv.x - 0.5) * aspect, sun_screen_uv.y - 0.5);
        vec2 uv = (uv_ac - sun_ac) / spike_size;
        vec3 col = vec3(spikes(uv));
        for (float i = 0.0; i < 64.0; i++) {
            col += 0.01 * spikes(uv + 0.5 * sin(vec2(i, i + 5.0) + 0.01 * TIME));
        }
        color += col;
        color *= occlusion_factor; // fade everything together as the sun goes behind an object
    }

    //float d = texture(depth_texture, SCREEN_UV).r; ALBEDO = vec3(d); ALPHA = 1.0; return;
    ALBEDO = color;
    ALPHA = color.r;

	float fuzz = 0.05f;
    if (sun_screen_uv.x < -fuzz || sun_screen_uv.x > 1.0 + fuzz || sun_screen_uv.y < -fuzz || sun_screen_uv.y > 1.0 + fuzz) {
    	discard; // Skip rendering for the second sun
	}
}
