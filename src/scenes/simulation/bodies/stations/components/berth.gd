class_name Berth
extends Node3D

@onready var collider: StaticBody3D = $BerthCollider
@export var clamps: Array[Clamp]

func set_velocity(velocity: Vector3) -> void:
	# Sets the collider velocity
	collider.constant_linear_velocity = velocity

func attach_clamps() -> void:
	for c in clamps:
		c.attach_clamps()
