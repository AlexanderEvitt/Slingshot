extends Node3D

var scaledown = 1

var cam

@export var camera_mode : bool
@export var planet_orbits : bool
@export var zoomable : bool
@export var hud_enable = false

func _ready():
	var spacecraft = get_node("Spacecraft")
	spacecraft.camera_mode = camera_mode
	
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
