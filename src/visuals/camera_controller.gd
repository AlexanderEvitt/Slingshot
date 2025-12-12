extends Node3D

# Zoom parameters
@export var zoom_distance := 200.0 # start zoom, then current zoom
var zoom_speed := 1.2 # multiplicative rate of zoom
var smooth_zoom := 0.2 # 1.0 is move instantly to new zoom, 0.0 is don't move
@export var zoom_min := 0.01 # minimum zoom distance
var zoom_max := 2000000000.0 # maximum zoom distance

# Motion of camera constants
@export var Kd := 0.99 # speed at which camera bounces back (1.0 = never moves)
@export var Kp := 0.5 # scale of motion from acceleration
@export var Ka := 0.1 # speed at which camera moves to new attitude

var camera_mode = "Global" # whether camera moves with ship or stays fixed

@onready var camera_rotator = $CameraRotator
@onready var camera = $CameraRotator/Camera3D

# Camera rotation parameters
var mouse_rotation_speed := 0.0001
var key_rotation_speed := 0.1
var r := false # whether to allow rotation
var pitch := 0.0 # start pitch
var yaw := 0.0 # start yaw

var viewer

func _ready():
	# Get the parent of the viewport, so you can see if the viewport is even visible
	# If it's not, don't bother moving the camera
	viewer = get_viewport().get_parent()

func _process(_delta):
	# Smoothly move to new position
	var old_zoom = camera.position.z
	camera.position = Vector3(0, 0, smooth_zoom*zoom_distance + (1.0 - smooth_zoom)*old_zoom)
	
	# Move camera back from acceleration
	# by linearly interpolating between current position and offset by thrust
	#var acceleration = ShipData.player_ship.acceleration
	#position = (Kd)*position + (1.0 - Kd)*Kp*(-acceleration)
	
	# Rotate camera to ship attitude if in "Local" mode
	if camera_mode == "Global":
		rotation = Vector3(0,-PI/2,-PI/2)
		if Input.is_action_just_pressed("view"):
			camera_mode = "Local"
	elif camera_mode == "Local":
		# Linearly interpolate to ship attitude, with Ka as the weight
		transform.basis = transform.basis.slerp(ShipData.player_ship.attitude, Ka)
		if Input.is_action_just_pressed("view"):
			camera_mode = "Global"
	
	# Set zoom from inputs
	if viewer.is_visible_in_tree():
		if Input.is_action_pressed("zoom_out") or Input.is_action_just_released("zoom_out"):
			zoom_distance = zoom_speed*zoom_distance
		if Input.is_action_pressed("zoom_in") or Input.is_action_just_released("zoom_in"):
			zoom_distance = zoom_distance/zoom_speed
		zoom_distance = clamp(zoom_distance, zoom_min, zoom_max)
		
		# Handle arrow keys rotation	
		if Input.is_action_pressed("mod_up"):
			pitch = pitch - key_rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_down"):
			pitch = pitch + key_rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_left"):
			yaw = yaw - key_rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_right"):
			yaw = yaw + key_rotation_speed
			set_orientation()

	# Right-click rotate
	if Input.is_action_pressed("right_click"):
		set_orientation()
		
func set_orientation():
	yaw -= Input.get_last_mouse_velocity().x * mouse_rotation_speed
	pitch = clamp(pitch - Input.get_last_mouse_velocity().y * mouse_rotation_speed, -1.57, 1.57)
	
	# Set rotation on the parent, CameraRig
	camera_rotator.rotation = Vector3(pitch, yaw, 0)
