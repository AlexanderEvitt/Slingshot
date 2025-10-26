extends Node3D

@onready var collider := $ColliderBody

func set_velocity(velocity):
	# Sets the collider velocity
	collider.constant_linear_velocity = velocity
