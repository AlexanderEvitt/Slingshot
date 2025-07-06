extends Node3D

var scaledown = 1

var cam

@export var camera_mode : bool
@export var camera_select = 3
@export var planet_orbits : bool
@export var zoomable : bool
@export var hud_enable = false

func _ready():
	var spacecraft = get_node("Spacecraft")
	spacecraft.camera_mode = camera_mode
	
	# Set which camera is active
	var first_cam = get_node("Spacecraft/Pointer/FirstCam")
	var third_cam = get_node("Spacecraft/CameraRig/CameraRotator/Camera3D")
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
	
	# this isn't set to the right camera
	cam = spacecraft.get_node("CameraRig/CameraRotator/Camera3D")
	cam.zoomable = zoomable
	if !zoomable:
		cam.get_parent().get_parent().rotation.z = 0 # changes orientation for attitude view
	# zoomable and unzoomable dist is set in the camera settings
	
	# Set orbits on or off
	#if !planet_orbits:
	#	var orbits = self.get_nodes_in_group("BodyOrbit")
	#	for o in orbits:
	#		o.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position += -cam.global_position/scaledown
	# Setting this root to the negative of the ship position ensures the cam is always at the global origin
	# Should not be necessary (and should have no effect) in a double precision build
	# But the atmosphere plugin needs this for some reason (jitters otherwise)
