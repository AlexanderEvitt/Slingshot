extends Panel

@export var orbit_scene_root: OrbitScene
@export var about: Label

# Bind buttons
@onready var frame_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/FrameButton
@onready var camera_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/CameraButton
@onready var waypoint_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/WaypointButton
@onready var request_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/RequestButton

# Get nodes from orbit scene (necessary to reparent them)
@onready var camera_rig: Node3D = orbit_scene_root.get_node("Dynamic/CameraRig")
@onready var waypoint_rig: WaypointRig = orbit_scene_root.get_node("WaypointRig")


func _ready() -> void:
	frame_button.pressed.connect(on_frame_change)
	camera_button.pressed.connect(on_cam_change)
	waypoint_button.pressed.connect(on_waypoint_select)
	request_button.pressed.connect(on_request_berth)


func _process(_delta: float) -> void:
	frame_button.disabled = true
	camera_button.disabled = true
	waypoint_button.disabled = true
	request_button.disabled = true

	var selected: Node3D = orbit_scene_root.selected_node
	if not is_instance_valid(selected):
		orbit_scene_root.selected_node = null  # clear stale reference
		return

	var sim_node: Node3D = _get_sim_node(selected)
	if sim_node == null:
		return

	about.text = sim_node.editor_description
	camera_button.disabled = false

	# Frame change only meaningful for gravitational bodies, not ships or missiles.
	if selected is BodyInheritor:
		frame_button.disabled = false

	# Waypoints only valid for static bodies; WaypointRig assumes its parent is a BodyInheritor.
	if selected is BodyInheritor:
		waypoint_button.disabled = false

	# Berth request only for stations.
	if sim_node.is_in_group("Stations"):
		request_button.disabled = false


# Returns the simulation-scene node that the given orbit proxy represents.
func _get_sim_node(proxy: Node3D) -> Node3D:
	if proxy is BodyInheritor:
		return ShipData.sim_root.get_node((proxy as BodyInheritor).body_path) as Node3D
	if proxy is Proxy:
		var obj: Node = (proxy as Proxy).sim_object
		return obj as Node3D if is_instance_valid(obj) else null
	return null


func on_frame_change() -> void:
	var selected: Node3D = orbit_scene_root.selected_node
	if selected is BodyInheritor:
		Conversions.frame_name = (selected as BodyInheritor).body_path


func on_cam_change() -> void:
	var selected: Node3D = orbit_scene_root.selected_node
	if selected == null:
		return
	camera_rig.reparent(selected)
	var tween: Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera_rig, "position", Vector3(0, 0, 0), 0.3)


func on_waypoint_select() -> void:
	var selected: Node3D = orbit_scene_root.selected_node
	if selected == null:
		return
	waypoint_rig.reparent(selected)
	waypoint_rig.position = Vector3(0, 0, 0)
	waypoint_rig.select_mode = true
	waypoint_rig.camera_rig = camera_rig


func on_request_berth() -> void:
	var selected: Node3D = orbit_scene_root.selected_node
	if selected is BodyInheritor:
		ShipData.player_ship.assign_berth((selected as BodyInheritor).body_path + "/Station/")
