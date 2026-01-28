extends Node3D

@export var GM : float

func _process(_delta: float) -> void:
	position = -ShipData.player_ship.position
	# Setting this root to the negative of the ship position ensures the cam is always near the global origin
	# Should not be necessary (and should have no effect) in a double precision build
	# But the atmosphere plugin needs this for some reason (jitters otherwise)
	# Updated to ship position from camera position
	# Because current external scene setup has cameras under different viewports from objects

func fetch(_time: float) -> Vector3:
	# Return origin of global reference frame
	return Vector3(0,0,0)

func fetch_velocity(_time: float) -> Vector3:
	# Claim that the origin is the origin of the inertial frame and thus has no velocity
	return Vector3(0,0,0)
