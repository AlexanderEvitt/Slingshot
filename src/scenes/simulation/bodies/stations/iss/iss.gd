@tool
extends Node3D

@onready var earth : Body = get_parent().get_parent()

func _process(_delta: float) -> void:
	look_at(earth.global_position)
	rotate_object_local(Vector3(1,0,0), PI/2)
