# Lens Flare System

A screen-space lens flare effect supporting up to 8 simultaneous light sources (the sun plus
engine plumes, missile exhaust, etc.) with per-source occlusion, colour tinting, and
independent rendering into multiple viewports.

---

## Overview

The system has two parts:

| File | Role |
|---|---|
| `lens_flare.gd` | GDScript driver — projects world positions to screen space and feeds the shader |
| `lens_flare.gdshader` | GLSL fragment shader — draws blobs, diffraction spikes, and ghost reflections |

A `MeshInstance3D` with a full-screen `QuadMesh` carries the shader material. One of these
nodes lives inside each viewport that should show the effect, as a child of that viewport's
camera.

---

## Blend mode: additive

The shader uses `render_mode blend_add`. In additive blending the GPU computes:

```
output = framebuffer + ALBEDO * ALPHA
```

This means the lens flare can only ever **brighten** the image — it never darkens or replaces
what's behind it. Standard alpha blending (`ALBEDO * ALPHA + background * (1 - ALPHA)`) would
replace dim background areas with the glow fringe colour, visibly darkening the star field
whenever multiple blobs overlapped. Additive blending avoids that entirely.

`ALPHA` is driven by the brightest colour channel (`max(r, g, b)`) so the effect is fully
transparent where there is no glow and fully opaque only at a source's white-hot centre.

---

## Full-screen quad

The vertex shader overrides clip-space position unconditionally:

```glsl
POSITION = vec4(VERTEX.xy, 1.0, 1.0);
```

This pins the quad to cover the entire screen regardless of where the node sits in the world,
making it a post-process overlay. `UV` still interpolates 0→1 across the quad and is used as
the screen coordinate for all effect calculations.

---

## CPU-side projection (`lens_flare.gd`)

Originally the shader projected each source's world position to screen space on every fragment,
running `PROJECTION_MATRIX * VIEW_MATRIX * pos` millions of times per frame. With 8 sources and
a 5×5 depth kernel that became expensive enough to tank frame time (5 ms → 55 ms with 24
missiles). The projection is now done once per source per frame on the CPU:

```gdscript
func _project_source(world_pos: Vector3) -> Vector3:
	...
	var screen_px := cam.unproject_position(world_pos)
	var screen_uv := screen_px / vp_size          # 0-1, y=0 at top
	var ndc_depth := cam.near / linear_depth       # reverse-Z: near=1, far≈0
	return Vector3(screen_uv.x, screen_uv.y, ndc_depth)
```

`ndc_depth = 0.0` is used as a sentinel — it signals "skip this source" and is never produced
by a valid projection (the value is clamped to a minimum of 0.001).

### UV conventions

`cam.unproject_position()` returns pixel coordinates with **y = 0 at the top** of the screen,
the same convention Godot uses for its depth texture. The shader receives this as `source_screen_uv`
and uses it directly for depth-buffer sampling (`depth_uv`). For blob and spike positioning,
the y axis is flipped (`1.0 - depth_uv.y`) to match the `QuadMesh`'s UV, which has y = 0 at
the **bottom**.

---

## Uniform array types

Godot 4 pads `vec3` arrays to `vec4` alignment (std140 layout) internally, but
`PackedVector3Array` passes data at 12 bytes per element. The GPU reads misaligned data and
the z component of every element arrives as zero — silently, with no error. The workaround is
to use types Godot handles correctly:

| Shader uniform | GDScript type |
|---|---|
| `uniform vec2 source_screen_uv[]` | `PackedVector2Array` |
| `uniform float source_ndc_depth[]` | `PackedFloat32Array` |
| `uniform float source_brightnesses[]` | `PackedFloat32Array` |
| `uniform vec3 source_colors[]` | `PackedVector3Array` *(xy only relied on)* |

---

## Occlusion

The depth buffer is sampled at the source's screen position and compared against `ndc_depth`
using `step(d, ndc_depth)`. In Godot 4's reverse-Z buffer near objects store **higher** values,
so a source passes the test (`occlusion = 1`) when the buffer shows nothing closer than it.

The sun (source 0) uses a **5×5 soft kernel** (25 samples, ±2 pixels, 0.4% of screen width
apart). This smooths the transition as the sun clips behind a planet horizon. All other sources
are point-lights with a **single sample** — the kernel would cost 25× per source per fragment
with no perceptible improvement for small objects.

---

## Visual effects

### Blob
A bright circular disc centred on the source. The falloff formula is:

```glsl
brightness / (d² * scale + 1.0)
```

`scale` (`blob_size` / `source_blob_size`) controls how quickly brightness falls off with
distance — higher values produce a tighter, smaller disc. `brightness` sets the peak. Both the
sun and other sources have independent parameters.

### Diffraction spikes
Six-pointed star produced by three overlapping spike arms at 0°, 60°, and 120°, each
implemented as a very narrow Lorentzian lobe. A distance falloff (`clamp(1 - length(p), 0, 1)`)
keeps the spikes tight to the source. Spike scale is independent for the sun and other sources.

### Ghost reflections (sun only)
Chromatic lens ghosts appear along the axis from the sun to the screen centre, simulating
internal reflections inside a camera lens. They are split across RGB channels to mimic
chromatic aberration. Ghosts are only computed for source 0 (the sun) — they are a feature
of a single dominant off-axis source and are not meaningful for engine plumes.

---

## Multiple viewports

The game has two independent viewports (first-person cockpit view and third-person external
view). Each has its own `MeshInstance3D` lens flare quad. Because the viewports share a
World3D, both cameras would otherwise see both quads — producing duplicate suns.

Two mechanisms prevent this:

**1. Independent material instances.** `_ready()` duplicates the shared `ShaderMaterial`
resource so each node has its own copy. Without this, all instances write to the same uniform
set and the last one to run each frame wins.

```gdscript
mat = get_active_material(0).duplicate()
set_surface_override_material(0, mat)
```

**2. Unique render layers.** Each instance claims one of the four reserved render layers
(layers 17–20, bits 16–19) and strips the other reserved bits from its camera's cull mask.
This makes each quad invisible to every camera except its own. Four slots means up to four
cameras can share the same World3D and each receive an independent lens flare.

```gdscript
layers = 1 << my_bit           # quad visible on this layer only
cam.cull_mask &= ~all_lf_bits  # camera ignores all lens-flare layers…
cam.cull_mask |= 1 << my_bit   # …except its own
```

Layers 17–20 were chosen because they are the highest available render layers in Godot 4
(render layers are capped at 20) and are unlikely to be used by anything else in the scene.

---

## Source priority

The shader supports `MAX_SOURCES = 8` slots. Slot 0 is always the sun. The remaining 7 slots
are filled by `Pinprick` nodes (engine plumes, missile exhaust) sorted by brightness, so the
most visible sources are always represented if there are more than 7 active pinpricks.
