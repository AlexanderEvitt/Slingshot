extends Node3D

@onready var collider := $BerthCollider

func set_velocity(velocity):
	# Sets the collider velocity
	collider.constant_linear_velocity = velocity
