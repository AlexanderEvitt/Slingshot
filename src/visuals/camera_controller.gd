extends Node

@export var zoom_distance := 200.0
var zoom_speed := 1.2
var smooth_zoom := 0.2 # 1.0 is move instantly to new zoom, 0.0 is don't move
@export var zoom_min := 7.0
var zoom_max := 2000000000.0

@onready var camera_rotator = $CameraRotator
@onready var camera = $CameraRotator/Camera3D

var rotation_speed := 0.0001
var r := false
var pitch := 0.0
var yaw := 0.0

var viewer

func _ready():
	# Get the parent of the viewport, so you can see if the viewport is even visible
	# If it's not, don't bother moving the camera
	viewer = get_viewport().get_parent()

func _process(_delta):
	# Set zoom from inputs
	if viewer.is_visible_in_tree():
		if Input.is_action_pressed("zoom_out") or Input.is_action_just_released("zoom_out"):
			zoom_distance = zoom_speed*zoom_distance
		if Input.is_action_pressed("zoom_in") or Input.is_action_just_released("zoom_in"):
			zoom_distance = zoom_distance/zoom_speed
		zoom_distance = clamp(zoom_distance, zoom_min, zoom_max)
		
		# Smoothly move to new position
		var old_zoom = camera.position.z
		camera.position = Vector3(0, 0, smooth_zoom*zoom_distance + (1.0 - smooth_zoom)*old_zoom)
		
		# Handle arrow keys rotation	
		if Input.is_action_pressed("mod_up"):
			pitch = pitch - 100*rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_down"):
			pitch = pitch + 100*rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_left"):
			yaw = yaw - 100*rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_right"):
			yaw = yaw + 100*rotation_speed
			set_orientation()


func _unhandled_input(event):
	# Right-click rotate
	if event is InputEventMouseButton and event.button_index == 2:
		if !r:
			r = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif r:
			r = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if r:
		set_orientation()
		
func set_orientation():
	yaw -= Input.get_last_mouse_velocity().x * rotation_speed
	pitch = clamp(pitch - Input.get_last_mouse_velocity().y * rotation_speed, -1.57, 1.57)
	
	# Set rotation on the parent, CameraRig
	camera_rotator.rotation = Vector3(pitch, yaw, 0)
