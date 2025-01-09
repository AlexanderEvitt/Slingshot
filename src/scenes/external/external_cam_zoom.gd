extends SubViewportContainer

var cam
var sun
var fov_label
var rate = 0.05

# Called when the node enters the scene tree for the first time.
func _ready():
	cam = get_node("SubViewport/CamRoot/Spacecraft/NarrowCam")
	fov_label = get_node("ScreenText/Label3")
	sun = get_node("SubViewport/CamRoot/Sun/SunSprite")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_visible_in_tree():
		if Input.is_action_pressed("zoom_out"):
			cam.fov = (1+rate)*cam.fov
		if Input.is_action_pressed("zoom_in"):
			cam.fov = (1-rate)*cam.fov
		cam.fov = clamp(cam.fov,5,100)
		fov_label.text = "FOV" + str(snapped(cam.fov,1))
	
	# Set the sun position in the lens flare shader
	var sun_point = cam.unproject_position(sun.global_position)
	material.set_shader_parameter("sun_position",sun_point)
	
	# Scale the sun with zoom
	sun.pixel_size = 0.3*cam.fov
