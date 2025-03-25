extends Node3D

var v
var cam
@export var retro : int
@export var side_check = true

# Called when the node enters the scene tree for the first time.
func _ready():
	cam = get_viewport().get_camera_3d()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if retro != 0:
		v = Conversions.VelToFrame(OwnShip.velocity,SystemTime.t)
		position = retro*v.normalized()/2
	
	if side_check:
		# Don't check for this if in HUD
		if (global_position.dot(cam.global_position)) > 0:
			visible = false
		else:
			visible = true
