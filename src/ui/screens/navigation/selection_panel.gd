extends Panel

@export var orbit_scene_root : Node
@export var about : Node

# Bind buttons
@onready var frame_button = $ScrollContainer/MarginContainer/VBoxContainer/FrameButton
@onready var camera_button = $ScrollContainer/MarginContainer/VBoxContainer/CameraButton
@onready var waypoint_button = $ScrollContainer/MarginContainer/VBoxContainer/WaypointButton
@onready var request_button = $ScrollContainer/MarginContainer/VBoxContainer/RequestButton

# Get nodes from orbit scene (necessary to reparent them)
@onready var camera_rig = orbit_scene_root.get_node("Ships/PlayerShip/CameraRig")
@onready var waypoint_rig = orbit_scene_root.get_node("WaypointRig")

func _ready():
	# Connect button presses to function calls
	frame_button.pressed.connect(on_frame_change)
	camera_button.pressed.connect(on_cam_change)
	waypoint_button.pressed.connect(on_waypoint_select)
	request_button.pressed.connect(on_request_berth)

func _process(_delta):
	# Buttons disabled unless you select something
	frame_button.disabled = true
	camera_button.disabled = true
	waypoint_button.disabled = true
	request_button.disabled = true
	
	# If you select a target
	if orbit_scene_root.selected_body != null:
		var selected = get_tree().root.get_node("GameRoot/" + orbit_scene_root.selected_body)
		about.text = selected.editor_description
		camera_button.disabled = false
		
		# Only allow frame and waypoint if user is not selecting the ship
		if orbit_scene_root.selected_body != "Ships/PlayerShip":
			frame_button.disabled = false
			waypoint_button.disabled = false
		
		# Only allow request berth if user is selecting a station
		if selected.station == true:
			request_button.disabled = false

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

func on_request_berth():
	# Tell the ship calculator to assign a berth
	ShipData.player_ship.assign_berth(orbit_scene_root.selected_body)
