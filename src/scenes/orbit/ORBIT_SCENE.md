# Orbit Scene

The orbit scene is a separate 3D view of the solar system used for navigation planning. It
runs in its own `SubViewport` (sharing the same `World3D` as the simulation viewport) and is
always live — bodies track their simulation counterparts every frame. The player uses it to
select objects, reframe the reference orbit, place waypoints, and request docking berths.

---

## Floating origin

The orbit scene root (`OrbitScene`) repositions itself every `_process()` tick so that the
active camera stays near world origin:

```gdscript
position = position - cam.global_position
```

This piggybacks on the same floating-origin strategy used by the simulation scene. Without it,
solar-system-scale coordinates would cause visible jitter in the 3D lines and mesh positions,
which lack the double-precision transforms that the physics scene uses.

`waypoint_plotter.gd` does the same thing independently by forcing `global_position =
Vector3(0,0,0)` every frame. It then reconstructs waypoint world positions from scratch using
`body.fetch(SimTime.t) + orbit_root.position` to account for the shifted root.

---

## Node hierarchy

```
OrbitScene  (orbit_scene_controller.gd)
├── Dynamic  (dynamic.gd)
│   ├── CameraRig      — starts here; reparented onto proxies on user request
│   └── <proxies>      — spawned at runtime: SpacecraftProxy, MissileProxy, …
├── <BodyInheritor nodes>   — static celestial bodies (planets, moons, stations)
│   └── ClickDetector  (click_detector.gd, Area3D in "Selectable" group)
└── WaypointRig        (waypoint_rig.gd)
    └── WaypointPlotter (waypoint_plotter.gd)
```

---

## Static bodies — BodyInheritor

Planets, moons, and stations are `BodyInheritor` nodes placed in the scene at edit time.
Each holds a `body_path: String` that points to the corresponding `Body` node in the
simulation scene. Every `_physics_process()` they read `body.get_local_position(SimTime.t)`
and update their own position accordingly.

Each static body has a child `ClickDetector` (an `Area3D` in the `"Selectable"` group).
`OrbitScene._ready()` iterates over every node in that group and connects
`Area3D.input_event` → `on_selected(…, body: Node3D)`, passing the `BodyInheritor` itself
as the payload.

---

## Dynamic objects — Dynamic node and Proxy

Dynamic sim objects (player ship, missiles) are not placed in the orbit scene at edit time.
Instead, any sim object that wants an orbit representation:

1. Adds itself to the `"Dynamic"` group in its own `_ready()`.
2. Implements `get_orbit_rep() -> PackedScene` returning the proxy scene to instantiate.
3. The proxy scene's root must extend `Proxy`.

`dynamic.gd` polls `get_nodes_in_group("Dynamic")` every `_process()` frame. When it sees a
node it hasn't tracked yet it instantiates the proxy, calls `proxy.set_sim_object(node)`, and
wires up any `"Selectable"` `Area3D` descendants so clicking them calls `on_selected(…,
proxy)`. Stale entries — proxies whose sim object has been freed — are culled each frame using
`is_instance_valid()`.

### Proxy base class

`proxy.gd` provides a template-method pattern:

```
_process() — validity guard → _sync()
_sync()    — override in subclasses; update position, attitude, visuals
```

`dynamic.gd` is the sole lifecycle owner. `Proxy._process()` deliberately does **not** call
`queue_free()` on itself; it just skips `_sync()` and waits to be culled.

### Transient rescue

When a proxy is about to be freed, `_rescue_transients()` checks each direct child. Any child
whose `owner` differs from the proxy itself was reparented into it from outside (e.g.
`CameraRig`, `WaypointRig`) and must be saved before the subtree is freed. Rescued nodes land
on the `SpacecraftProxy` if one exists, otherwise on the `Dynamic` node itself.

---

## Selection

`OrbitScene.selected_node: Node3D` holds a reference to whichever orbit proxy (or
`BodyInheritor`) was last clicked. It is set by `on_selected()` and is never actively cleared
by the orbit scene itself — `selection_panel.gd` checks `is_instance_valid(selected_node)`
each frame and nulls it out if the proxy has since been freed.

`selection_panel.gd` translates `selected_node` into a simulation-scene node via
`_get_sim_node()` for anything that needs data from the sim (description text, group
membership for berth requests). The mapping is:

- `BodyInheritor` → `ShipData.sim_root.get_node(body_path)`
- `Proxy` subclass → `proxy.sim_object` (after an `is_instance_valid` guard)

Button availability rules:

| Button | Condition |
|---|---|
| Frame | Selected node is a `BodyInheritor` (gravitational body only) |
| Camera | Anything selected |
| Waypoint | Anything selected that is not the player ship (`SpacecraftProxy`) |
| Request Berth | Sim node is in the `"Stations"` group |

---

## Camera and waypoint rigs

`CameraRig` and `WaypointRig` are physically reparented around the scene tree so they
inherit the selected object's transform. `on_cam_change()` calls `reparent()` and then tweens
`position` back to zero over 0.3 s. `on_waypoint_select()` does the same for
`WaypointRig` before engaging selection mode.

Waypoint placement is a two-click process managed entirely inside `waypoint_rig.gd`:

- Click 1 — intersect mouse ray with the XY plane through the rig's origin; locks the
  in-plane position.
- Click 2 — intersect mouse ray with a vertical plane through the first hit point;
  takes only the Z component, giving the altitude above or below the orbital plane.

On the second click the waypoint is committed to `ShipData.player_ship.waypoints` as
`{"Frame": body_node, "Position": hit}` and `waypoints_updated` is emitted.

---

## ⚠️ Design issues worth revisiting

### `_sync()` runs every frame for new-member detection

`dynamic.gd` calls `_sync()` from `_process()`, which iterates the entire `"Dynamic"` group
every frame solely to discover nodes that joined since last time. New sim objects appear at
most once per spawn event — there is no reason to poll every frame. A signal emitted by the
sim object when it joins the group (or a dedicated `"DynamicSpawned"` signal on `ShipData`)
would limit the work to actual spawn events and make the intent clearer.

### `BodyInheritor` is not called `BodyProxy`

The file is `body_proxy.gd`. Everything else in this scene uses the name "Proxy".
The class is still called `BodyInheritor`. Rename it to `BodyProxy` to match.

### Two places wire up click detectors

Static body click detectors are connected in `OrbitScene._ready()`; dynamic proxy click
detectors are connected in `dynamic.gd._sync()`. The logic is the same — both end up calling
`on_selected.bind(node)` — but it lives in two different files with no shared helper. If the
connection logic ever changes (e.g. adding a double-click handler) it must be updated in both
places.

### `selected_node` is never cleared by the orbit controller

When a proxy is freed, `selected_node` goes stale silently. The selection panel catches this
in `_process()` the following frame, but the orbit controller itself has no awareness that its
selection was invalidated. A `tree_exiting` connection on the newly-selected proxy (cleared
when a new selection is made) would let the controller null `selected_node` immediately.

### Reparenting rigs is fragile by design

Moving `CameraRig` and `WaypointRig` around the scene tree to follow the selected object is
the root cause of the freed-parent crash that required `_rescue_transients()`. A simpler
model: keep both rigs as permanent children of `OrbitScene` (or `Dynamic`), and have them
track a `target: Node3D` reference they lerp toward each frame. No reparenting, no rescue
needed, and the camera smoothly follows objects that move rather than snapping to their
position at the moment of selection.

### ~~`WaypointRig` assumes its parent is always a `BodyInheritor`~~ *(fixed)*

`selection_panel.gd` now enables the waypoint button only when `selected is BodyInheritor`,
so `WaypointRig` is never reparented onto a dynamic proxy. The UI layer enforces the
invariant that `WaypointRig._input()` relies on.

### `WaypointRig.begin_selection()` is dead code

`selection_panel.gd` sets `waypoint_rig.select_mode = true` directly, bypassing
`begin_selection()`, which also resets `click_count`, `hit`, and `xy_hit`. If `begin_selection()`
is the intended API, use it. If direct property access is intentional, delete the method.

### `click_detector.gd` navigates the scene tree by position

```gdscript
@onready var camera_rig: ExternalCameraRig = get_viewport().get_camera_3d().get_parent().get_parent()
```

Two blind `.get_parent()` calls assume a fixed camera hierarchy. If the camera is ever
restructured this breaks silently at runtime with a null-cast error. Use an `@export` or a
named `get_node()` path instead.

### `fake_radar.gd` deep-couples to player ship internals

```gdscript
ShipData.player_ship.defense_module.active_threats
```

The radar script accesses a specific module on a specific ship by drilling three levels deep
through singletons. If `defense_module` is absent (e.g. a ship type that has no point
defence) this crashes. The defense module reference should be passed in via `@export` or
injected at spawn time, the same way `set_sim_object()` works for other proxy data.
