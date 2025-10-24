extends Node3D

@export var GM : float
@export var body_path : String

func fetch(_time):
	# Return origin of global reference frame
	return Vector3(0,0,0)

func fetch_velocity(_time):
	# Claim that the origin is the origin of the inertial frame and thus has no velocity
	return Vector3(0,0,0)
