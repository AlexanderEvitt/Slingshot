extends Node3D

@onready var pointer = $Pointer

func _process(_delta):
	pointer.transform.basis = ShipData.player_ship.attitude
	global_position = ShipData.player_ship.global_position
