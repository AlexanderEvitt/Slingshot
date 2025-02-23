extends MeshInstance3D

var sun
var cam
var mat


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the sun
	sun = get_parent().get_parent().get_parent().get_parent().get_parent().get_node("Sun")
	
	# Get the camera
	cam = get_viewport().get_camera_3d()

	# Get material
	mat = get_active_material(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Set the sun position in the lens flare shader
	# should subtract camera position but it's fine as long as camera is near origin
	mat.set_shader_parameter("sun_world_position",sun.global_position - cam.global_position)
