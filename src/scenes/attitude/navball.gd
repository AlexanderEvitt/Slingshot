extends Node3D

var origin: Vector3
var pointing: Vector3

func _process(_delta: float) -> void:
	origin = Conversions.find_body(SimTime.t)
	pointing = origin - ShipData.player_ship.position
	look_at(pointing,Vector3(0,0,1))
