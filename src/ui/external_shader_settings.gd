extends SubViewportContainer

var sun
var cam
@export var cam_index := 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var cameras = [get_node("SubViewport/CamRoot/Spacecraft/NarrowCam"),get_node("SubViewport/CamRoot/Spacecraft/CameraRig/CameraRotator/Camera3D")]
	# Set which camera is used
	cam = cameras[cam_index]
	cam.current = true
	
	# Get the sun
	sun = get_node("SubViewport/CamRoot/Sun/SunSprite")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Set the sun position in the lens flare shader
	var sun_point = cam.unproject_position(sun.global_position)
	material.set_shader_parameter("sun_position",sun_point)
	
	var render_spikes = cam.is_position_behind(sun.global_position)
	material.set_shader_parameter("show_sun",!render_spikes)
