extends Node3D

var v
var cam
@export var retro : int
@export var side_check = true

func _ready():
	cam = get_viewport().get_camera_3d()


func _process(_delta: float) -> void:
	if retro != 0:
		v = Conversions.VelToFrame(ShipData.player_ship.velocity,SystemTime.t)
		position = retro*v.normalized()/2
	
	if side_check:
		# Don't check for this if in HUD
		if (global_position.dot(cam.global_position)) > 0:
			visible = false
		else:
			visible = true
