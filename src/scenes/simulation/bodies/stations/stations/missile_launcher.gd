class_name MissileLauncher
extends Node3D

@export var missile_scene: PackedScene
@export var batch_size: int = 18
@export var kickoff_velocity: float = 0.1
@export var spread_velocity: float = 0.1
@export var fire_interval: float = 20.0
@export var stagger_time: float = 0.2  # seconds between each missile in a batch

var time_since_last_fire: float = 0.0
var pending_launches: Array = []  # Array of [time_remaining, launch_vel]
var station: Station


func _ready() -> void:
	station = get_parent()


func _physics_process(delta: float) -> void:
	time_since_last_fire += delta
	if Input.is_action_just_pressed("fire") or time_since_last_fire >= fire_interval:
		time_since_last_fire = 0.0
		_queue_batch()

	# Count down and launch pending missiles
	for i in range(pending_launches.size() - 1, -1, -1):
		pending_launches[i][0] -= delta
		if pending_launches[i][0] <= 0.0:
			_launch(pending_launches[i][1])
			pending_launches.remove_at(i)


func _queue_batch() -> void:
	var indices := range(batch_size)
	indices.shuffle()
	for i in range(batch_size):
		var angle: float = (TAU / batch_size) * indices[i]
		var spread_dir: Vector3 = (global_transform.basis.x * cos(angle) + global_transform.basis.z * sin(angle))
		var up: Vector3 = global_transform.basis.y
		var launch_vel: Vector3 = station.fetch_velocity(SimTime.t) + up * kickoff_velocity + spread_dir * spread_velocity
		pending_launches.append([stagger_time * i, launch_vel])


func _launch(launch_vel: Vector3) -> void:
	var spawn_pos: Vector3 = station.fetch(SimTime.t) + global_transform.basis * position
	var missile: Missile = missile_scene.instantiate()
	add_child(missile)
	missile.initialize(spawn_pos, launch_vel, global_transform.basis)
