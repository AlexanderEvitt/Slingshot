extends Node3D

var mat: ShaderMaterial
var cam: Camera3D
var prev_basis: Basis  # Store previous camera basis for rotation calculation
var damped_angle := 0.0
var damped_axis := Vector3(0,0,0)
var w := 0.9 # blend to use for damping
var s := 0.1 # scale of angle displacements

func _ready() -> void:
	var tracks: MeshInstance3D = $StarTracks
	mat = tracks.get_active_material(0)
	cam = get_viewport().get_camera_3d()
	prev_basis = cam.global_transform.basis  # Initialize previous basis

func _process(_delta: float) -> void:
	# Update camera (as it changes during ready)
	cam = get_viewport().get_camera_3d()
	
	var current_basis: Basis = cam.global_transform.basis
	var rotation_change: Basis = current_basis * prev_basis.inverse()
	
	# Extract rotation axis and angle
	var rotation_axis: Vector3 = rotation_change.get_rotation_quaternion().get_axis()
	var rotation_angle: float =  rotation_change.get_rotation_quaternion().get_angle()  # The rotation angle (float, in radians)

	# Damp angle so it winds up and winds down
	# Only change axis if there's actual rotation
	if rotation_angle > 0.001:
		damped_axis = rotation_axis
	damped_angle = (w*damped_angle + (1-w)*rotation_angle)

	# Send values to shader
	mat.set_shader_parameter("rotation_axis", damped_axis)
	mat.set_shader_parameter("rotation_angle", s*damped_angle)
	mat.set_shader_parameter("brightness", bright(damped_angle))

	# Update previous basis for next frame
	prev_basis = current_basis
	
	global_transform.basis = Basis()

func bright(angle: float) -> float:
	var lim := PI/12.0
	var b := (lim - angle)/lim
	return clamp(b,0,1)
