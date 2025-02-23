extends Node3D

var mat
var cam
var prev_basis: Basis  # Store previous camera basis for rotation calculation
var damped_angle = 0
var damped_axis = Vector3(0,0,0)
var w = 0.9

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mat = get_node("StarTracks").get_active_material(0)
	cam = get_viewport().get_camera_3d()
	prev_basis = cam.global_transform.basis  # Initialize previous basis

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var current_basis = cam.global_transform.basis
	var rotation_change = current_basis * prev_basis.inverse()
	
	# Extract rotation axis and angle
	var rotation_axis = rotation_change.get_rotation_quaternion().get_axis()
	var rotation_angle =  rotation_change.get_rotation_quaternion().get_angle()  # The rotation angle (float, in radians)
	
	# Damp angle so it winds up and winds down
	# Only change axis if there's actual rotation
	if rotation_angle > 0.01:
		damped_axis = rotation_axis
	damped_angle = (w*damped_angle + (1-w)*rotation_angle)

	# Send values to shader
	mat.set_shader_parameter("rotation_axis", damped_axis)
	mat.set_shader_parameter("rotation_angle", damped_angle)

	# Update previous basis for next frame
	prev_basis = current_basis
	
	global_transform.basis = Basis()
