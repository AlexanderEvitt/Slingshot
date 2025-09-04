extends Panel

@export var orbit_scene_root : Node
@export var about : Node

# Bind buttons
@onready var frame_button = $ScrollContainer/MarginContainer/VBoxContainer/FrameButton
@onready var camera_button = $ScrollContainer/MarginContainer/VBoxContainer/CameraButton
@onready var waypoint_button = $ScrollContainer/MarginContainer/VBoxContainer/WaypointButton
@onready var target_button = $ScrollContainer/MarginContainer/VBoxContainer/TargetButton

# Get nodes from orbit scene (necessary to reparent them)
@onready var camera_rig = orbit_scene_root.get_node("Ships/PlayerShip/CameraRig")
@onready var waypoint_rig = orbit_scene_root.get_node("WaypointRig")

func _ready():
	# Connect button presses to function calls
	frame_button.pressed.connect(on_frame_change)
	camera_button.pressed.connect(on_cam_change)
	waypoint_button.pressed.connect(on_waypoint_select)

func _process(_delta):
	if orbit_scene_root.selected_body != null:
		var selected = get_tree().root.get_node("GameRoot/" + orbit_scene_root.selected_body)
		about.text = selected.editor_description

func on_frame_change():
	# Give the Conversions autoload a new frame path based on the selected body
	Conversions.frame_name = orbit_scene_root.selected_body

func on_cam_change():
	# Reparent the camera to the selected body
	camera_rig.reparent(orbit_scene_root.get_node(orbit_scene_root.selected_body))
	# Move the camera rig to its new parent
	camera_rig.position = Vector3(0,0,0)
	
func on_waypoint_select():
	# Reparent the rig to the selected body
	waypoint_rig.reparent(orbit_scene_root.get_node(orbit_scene_root.selected_body))
	# Move the rig to its new parent
	waypoint_rig.position = Vector3(0,0,0)
	# Active waypoint selection mode
	waypoint_rig.select_mode = true
	# Give the waypoint rig the camera rig reference
	waypoint_rig.camera_rig = camera_rig
