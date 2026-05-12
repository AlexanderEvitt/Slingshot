class_name Plotter
extends Drawer

@export var color: Color

# Set externally every frame by SpacecraftProxy._sync or PlayerShip._physics_process.
# PropagateModule publishes a brand-new array object each time it refreshes
# (~every 10 frames), and reuses the same object in between.
var positions: Array[Vector3]

# Previous positions reference — compared by identity so the check is O(1).
# A rebuild is triggered only when PropagateModule has published a new object.
var _prev_positions: Array[Vector3]

# Persistent mesh objects — material and MeshInstance are created once in
# _ready() and reused; only the ImmediateMesh surface data is replaced each
# time the trajectory is rebuilt.
var _mesh_instance: MeshInstance3D
var _material: ORMMaterial3D

# Cached reference to the frame body node (e.g. Earth). Looked up once in
# _ready() so _process never calls get_node() per frame.
var _frame_body: Node

# Variables for shifting traj
var initial_planet_pos: Vector3
var original_traj_pos: Vector3


func _ready() -> void:
	# Build the persistent material once — settings never change between updates.
	_material = ORMMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = color
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Build the persistent MeshInstance3D — only its mesh data is swapped on rebuild.
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh_instance)

	# Cache the frame body node; reconnect whenever the reference frame changes.
	_frame_body = ShipData.sim_root.get_node(Conversions.frame_name)
	Conversions.frame_changed.connect(_on_frame_changed)


func _process(delta: float) -> void:
	# is_same() is an O(1) reference check — only false when PropagateModule has
	# published a new plotted_positions array, which happens every ~10 frames.
	if not is_same(positions, _prev_positions):
		_prev_positions = positions
		if positions.size() > 0:
			_rebuild_mesh()
			original_traj_pos = ShipData.player_ship.system_position
			_mesh_instance.position = Vector3.ZERO
			initial_planet_pos = Conversions.find_body(SimTime.t)
		else:
			# Empty positions (e.g. ship berthed) — hide the trajectory line.
			_mesh_instance.mesh = null

	# Drift the line each frame to track the ship's motion relative to the
	# reference body, avoiding a visible jump at the next trajectory rebuild.
	# Uses the cached _frame_body reference instead of get_node() + .call() per frame.
	if _mesh_instance.mesh != null:
		var body_vel: Vector3 = _frame_body.call("fetch", SimTime.t + 1.0) - _frame_body.call("fetch", SimTime.t)
		_mesh_instance.position -= (ShipData.player_ship.system_velocity - body_vel) * delta * SimTime.step


func _on_frame_changed() -> void:
	_frame_body = ShipData.sim_root.get_node(Conversions.frame_name)


func _rebuild_mesh() -> void:
	# Replace only the ImmediateMesh surface data; the MeshInstance3D and
	# material are reused so no add_child / queue_free churn occurs.
	var immediate_mesh := ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _material)
	for p: Vector3 in positions:
		immediate_mesh.surface_add_vertex(p)
	immediate_mesh.surface_end()
	_mesh_instance.mesh = immediate_mesh
