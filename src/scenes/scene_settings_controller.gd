extends Node3D

var scaledown = 1

var cam

@export var camera_mode : bool
@export var camera_select = 3
@export var planet_orbits : bool
@export var zoomable : bool
@export var hud_enable = false

var selected_body = null

func _ready():
	var spacecraft = get_node("Ships/PlayerShip")
	spacecraft.camera_mode = camera_mode
	
	# Set which camera is active
	var first_cam = get_node("Ships/PlayerShip/Pointer/FirstCam")
	var third_cam = get_node("Ships/PlayerShip/CameraRig/CameraRotator/Camera3D")
	var cinema_cam = get_node("CinemaCam")
	first_cam.current = false
	third_cam.current = false
	cinema_cam.current = false
	if camera_select == 3:
		third_cam.current = true
	elif camera_select == 1:
		first_cam.current = true
	else:
		cinema_cam.current = true
	
	# Get the camera node (is this the right camera?)
	cam = spacecraft.get_node("CameraRig/CameraRotator/Camera3D")
	
	# Connect the click detector signal
	var selectables = get_tree().get_nodes_in_group("Selectable")
	for s in selectables:
		var body_path = s.get_parent().body_path
		s.input_event.connect(on_selected.bind(body_path))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position += -cam.global_position/scaledown
	# Setting this root to the negative of the ship position ensures the cam is always at the global origin
	# Should not be necessary (and should have no effect) in a double precision build
	# But the atmosphere plugin needs this for some reason (jitters otherwise)

func on_selected(_camera, event, _click_position, _click_normal, _shape_idx, body_path):
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		selected_body = body_path
