extends Camera3D

var viewer
var zoom_speed = 1.2

# Called when the node enters the scene tree for the first time.
func _ready():
	viewer = get_viewport().get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if viewer.is_visible_in_tree():
		if Input.is_action_pressed("zoom_out"):
			size = zoom_speed*size
		if Input.is_action_pressed("zoom_in"):
			size = size/zoom_speed
		size = clamp(size, 10, 10000000)
