class_name Berth
extends Node3D

@onready var collider: AnimatableBody3D = $BerthCollider
@export var clamps: Array[Clamp]
@onready var setup_position: Vector3 = position

func set_velocity(velocity: Vector3) -> void:
	# Sets the collider velocity
	collider.constant_linear_velocity = velocity

func attach_clamps() -> void:
	for c in clamps:
		c.attach_clamps()
