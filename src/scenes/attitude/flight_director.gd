extends Node3D

var v: Vector3
var cam: Camera3D
@export var side_check := true
@onready var fc: AttitudeModule = ShipData.player_ship.attitude_module

func _ready() -> void:
	cam = get_viewport().get_camera_3d()


func _process(_delta: float) -> void:
	v = fc.target_attitude*Vector3(1,0,0)
	position = v.normalized()/2
	
	if side_check:
		# Don't check for this if in HUD
		if (global_position.dot(cam.global_position)) > 0:
			visible = false
		else:
			visible = true
