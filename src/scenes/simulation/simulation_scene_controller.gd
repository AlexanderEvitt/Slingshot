extends Node3D

@export var GM : float
# Reference to solar system root node SolarSystem
@export var solar_system : Node3D

func _process(_delta: float) -> void:
	solar_system.position = -ShipData.get_floating_frame_origin()

func fetch(_time: float) -> Vector3:
	# Return origin of global reference frame
	return Vector3(0,0,0)

func fetch_velocity(_time: float) -> Vector3:
	# Claim that the origin is the origin of the inertial frame and thus has no velocity
	return Vector3(0,0,0)
