class_name BodyCollider
extends Node3D

@onready var collider: StaticBody3D = $BerthCollider

func set_velocity(velocity: Vector3) -> void:
	# Sets the collider velocity
	collider.constant_linear_velocity = velocity
