extends Node3D

func _process(_delta: float) -> void:
	transform.basis = ShipData.player_ship.attitude
