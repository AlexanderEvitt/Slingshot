extends MeshInstance3D

var sun: Node3D
var cam: Camera3D
var mat: ShaderMaterial

const SUN_BRIGHTNESS := 0.7
const MAX_SOURCES := 8  # Must match MAX_SOURCES in lens_flare.gdshader

# Reserve the top 4 render layers (bits 16-19 = layers 17-20) for lens flare quads.
# Each instance claims one so it is invisible to every other camera sharing this world.
const _LF_BITS := [16, 17, 18, 19]
# Keyed by World3D so cameras in separate worlds reuse bits without conflict.
# Cameras sharing a world each get a unique bit from the pool.
static var _world_bit_counter: Dictionary = {}

func _ready() -> void:
	sun = ShipData.sim_root.get_node("SolarSystem/Sun")
	# Bind to the camera this quad is a child of, not whichever happens to be current.
	# Using get_viewport().get_camera_3d() breaks when multiple cameras share a viewport.
	cam = get_parent() as Camera3D
	# Duplicate material so each instance has its own shader parameter set.
	mat = get_active_material(0).duplicate()
	set_surface_override_material(0, mat)
	# Claim a unique render layer within this World3D and strip all reserved bits
	# from this camera except ours, so quads from other cameras are invisible here.
	var world: World3D = get_viewport().world_3d
	if not _world_bit_counter.has(world):
		_world_bit_counter[world] = 0
	var world_count: int = _world_bit_counter[world]
	if world_count >= _LF_BITS.size():
		push_error("LensFlare: more cameras share World3D '%s' than there are reserved layer slots (%d). Increase _LF_BITS." % [world.resource_path, _LF_BITS.size()])
	var my_bit: int = _LF_BITS[world_count % _LF_BITS.size()]
	_world_bit_counter[world] = world_count + 1
	layers = 1 << my_bit
	for b: int in _LF_BITS:
		cam.cull_mask &= ~(1 << b)
	cam.cull_mask |= 1 << my_bit
	print("LensFlare | quad: %s | cam: %s | bit: %d | cull_mask: %s" % [
		get_path(), cam.get_path(), my_bit, _bits(cam.cull_mask)])

# Projects a world-space position to screen data for the shader.
# Returns Vector3(screen_uv.x, screen_uv.y, ndc_depth), or ZERO if behind camera / off-screen.
func _project_source(world_pos: Vector3) -> Vector3:
	if cam == null or cam.is_position_behind(world_pos):
		return Vector3.ZERO
	var vp_size := get_viewport().get_visible_rect().size
	var screen_px := cam.unproject_position(world_pos)
	var screen_uv := screen_px / vp_size
	const FUZZ := 0.05
	if screen_uv.x < -FUZZ or screen_uv.x > 1.0 + FUZZ or screen_uv.y < -FUZZ or screen_uv.y > 1.0 + FUZZ:
		return Vector3.ZERO
	# ndc_depth for reverse-Z: near objects → 1, far objects → 0
	var linear_depth: float = (world_pos - cam.global_position).dot(-cam.global_transform.basis.z)
	var ndc_depth := clampf(cam.near / maxf(linear_depth, cam.near * 0.001), 0.001, 1.0)
	# screen_uv and depth texture share the same y=0-at-top convention — no flip needed
	return Vector3(screen_uv.x, screen_uv.y, ndc_depth)

func _process(_delta: float) -> void:
	if not cam.current:
		return  # don't update shader params for a camera that isn't rendering
	var screen_uvs   := PackedVector2Array()
	var ndc_depths   := PackedFloat32Array()
	var brightnesses := PackedFloat32Array()
	var colors       := PackedVector3Array()
	# Sun is always source 0 — only source 0 receives ghost reflections
	var sun_sd := _project_source(sun.global_position)
	screen_uvs.append(Vector2(sun_sd.x, sun_sd.y))
	ndc_depths.append(sun_sd.z)
	brightnesses.append(SUN_BRIGHTNESS)
	colors.append(Vector3(1.3, 1.15, 1.0))  # warm white sun tint

	# Collect Pinpricks, sort by apparent brightness so the most visible ones
	# fill the limited shader slots if there are more than MAX_SOURCES - 1
	var candidates: Array = []
	for p: Pinprick in get_tree().get_nodes_in_group("Pinpricks"):
		#var dist_sq := cam.global_position.distance_squared_to(p.global_position)
		#var apparent: float = sqrt(p.brightness / maxf(dist_sq, 1.0))
		candidates.append({ "node": p, "apparent": p.brightness })

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.apparent > b.apparent)

	for c: Dictionary in candidates:
		if screen_uvs.size() >= MAX_SOURCES:
			break
		var p: Pinprick = c.node
		var sd := _project_source(p.global_position)
		screen_uvs.append(Vector2(sd.x, sd.y))
		ndc_depths.append(sd.z)
		@warning_ignore("unsafe_call_argument")
		brightnesses.append(c.apparent)
		colors.append(Vector3(p.color.r, p.color.g, p.color.b))

	mat.set_shader_parameter("source_screen_uv",   screen_uvs)
	mat.set_shader_parameter("source_ndc_depth",   ndc_depths)
	mat.set_shader_parameter("source_brightnesses", brightnesses)
	mat.set_shader_parameter("source_colors",       colors)
	mat.set_shader_parameter("source_count",        screen_uvs.size())


# GDScript has no %b format specifier; build a 20-bit binary string manually.
func _bits(mask: int) -> String:
	var s: String = ""
	for i: int in range(19, -1, -1):
		s += "1" if (mask >> i) & 1 else "0"
	return s
