class_name MissileLauncher
extends Node3D

@export var missile_scene: PackedScene

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("fire"):
		var station: Station = get_parent()
		var missile: Missile = missile_scene.instantiate()
		add_child(missile)
		missile.initialize(station.fetch(SimTime.t) + position, station.fetch_velocity(SimTime.t), global_transform.basis)
