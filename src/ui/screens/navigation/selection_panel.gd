extends Panel

@export var orbit_scene_root : OrbitScene
@export var about : Label

# Bind buttons
@onready var frame_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/FrameButton
@onready var camera_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/CameraButton
@onready var waypoint_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/WaypointButton
@onready var request_button: Button = $ScrollContainer/MarginContainer/VBoxContainer/RequestButton

# Get nodes from orbit scene (necessary to reparent them)
@onready var camera_rig: Node3D = orbit_scene_root.get_node("Ships/PlayerShip/CameraRig")
@onready var waypoint_rig: WaypointRig = orbit_scene_root.get_node("WaypointRig")

func _ready() -> void:
	# Connect button presses to function calls
	frame_button.pressed.connect(on_frame_change)
	camera_button.pressed.connect(on_cam_change)
	waypoint_button.pressed.connect(on_waypoint_select)
	request_button.pressed.connect(on_request_berth)

func _process(_delta: float) -> void:
	# Buttons disabled unless you select something
	frame_button.disabled = true
	camera_button.disabled = true
	waypoint_button.disabled = true
	request_button.disabled = true
	
	# If you select a target
	if orbit_scene_root.selected_body != "":
		var selected: Node3D = ShipData.sim_root.get_node(orbit_scene_root.selected_body)
		about.text = selected.editor_description
		camera_button.disabled = false
		
		# Only allow frame and waypoint if user is not selecting the ship
		if orbit_scene_root.selected_body != "Ships/PlayerShip":
			frame_button.disabled = false
			waypoint_button.disabled = false
		
		# Only allow request berth if user is selecting a station
		if selected.is_in_group("Stations"):
			request_button.disabled = false

func on_frame_change() -> void:
	# Give the Conversions autoload a new frame path based on the selected body
	Conversions.frame_name = orbit_scene_root.selected_body

func on_cam_change() -> void:
	# Reparent the camera to the selected body
	camera_rig.reparent(orbit_scene_root.get_node(orbit_scene_root.selected_body))
	# Move the camera rig to its new parent (by smoothly tweening to zero)
	var tween: Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera_rig, "position", Vector3(0,0,0), 0.3)
	
func on_waypoint_select() -> void:
	# Reparent the rig to the selected body
	waypoint_rig.reparent(orbit_scene_root.get_node(orbit_scene_root.selected_body))
	# Move the rig to its new parent
	waypoint_rig.position = Vector3(0,0,0)
	# Active waypoint selection mode
	waypoint_rig.select_mode = true
	# Give the waypoint rig the camera rig reference
	waypoint_rig.camera_rig = camera_rig

func on_request_berth() -> void:
	# Tell the ship calculator to assign a berth
	ShipData.player_ship.assign_berth(orbit_scene_root.selected_body + "/Station/")
