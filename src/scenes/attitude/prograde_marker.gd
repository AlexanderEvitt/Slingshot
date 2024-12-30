extends Node3D

var v
var cam
@export var retro : int

# Called when the node enters the scene tree for the first time.
func _ready():
	cam = get_viewport().get_camera_3d()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if retro != 0:
		v = Conversions.VelToFrame(OwnShip.velocity,0)
		position = retro*v.normalized()/2
	
	if (global_position.dot(cam.global_position)) > 0:
		visible = false
	else:
		visible = true
