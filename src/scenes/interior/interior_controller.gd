extends Node3D

func _process(_delta: float) -> void:
	transform.basis = ShipData.player_ship.attitude
	rotate_object_local(Vector3(0,0,1), -PI/2)
