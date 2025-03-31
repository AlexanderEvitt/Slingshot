extends SubViewportContainer

var cam
var sun
var fov_label
var rate = 0.05

# Only set the fov label text if it exists
@export var set_fov = true

# Called when the node enters the scene tree for the first time.
func _ready():
	cam = get_node("SubViewport/CamRoot/Spacecraft/Pointer/FirstCam")
	if set_fov:
		fov_label = get_node("ScreenText/Label3")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_visible_in_tree():
		# Allow zooming
		if Input.is_action_pressed("zoom_out"):
			cam.fov = (1+rate)*cam.fov
		if Input.is_action_pressed("zoom_in"):
			cam.fov = (1-rate)*cam.fov
		cam.fov = clamp(cam.fov,5,100)
		
		# Only set label zoom if it exists
		if fov_label != null:
			fov_label.text = "FOV" + str(snapped(cam.fov,1))
	
	
