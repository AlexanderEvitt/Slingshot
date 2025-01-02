extends SubViewportContainer

var cam
var fov_label
var rate = 0.05

# Called when the node enters the scene tree for the first time.
func _ready():
	cam = get_node("SubViewport/CamRoot/Spacecraft/NarrowCam")
	fov_label = get_node("ScreenText/Label3")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("zoom_out"):
		cam.fov = (1+rate)*cam.fov
	if Input.is_action_pressed("zoom_in"):
		cam.fov = (1-rate)*cam.fov
	cam.fov = clamp(cam.fov,5,100)
	fov_label.text = "FOV" + str(snapped(cam.fov,1))
