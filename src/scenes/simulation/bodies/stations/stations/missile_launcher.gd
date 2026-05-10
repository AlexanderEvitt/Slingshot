class_name MissileLauncher
extends Node3D

@export var missile_scene: PackedScene
@export var batch_size: int = 36
@export var kickoff_velocity: float = 0.1  # km/s along launcher up axis
@export var fire_interval: float = 60.0
@export var stagger_time: float = 0.2      # seconds between each missile in a batch
@export var bias_magnitude: float = 0.02  # km/s² constant lateral acceleration bias per missile

var time_since_last_fire: float = 0.0
var pending_launches: Array = []  # Array of [time_remaining, launch_vel, bias_vec]
var station: Station


func _ready() -> void:
	station = get_parent()


func _physics_process(delta: float) -> void:
	time_since_last_fire += delta
	if Input.is_action_just_pressed("fire"):
		time_since_last_fire = 0.0
		_queue_batch()

	# Count down and launch pending missiles
	for i in range(pending_launches.size() - 1, -1, -1):
		pending_launches[i][0] -= delta
		if pending_launches[i][0] <= 0.0:
			_launch(pending_launches[i][1], pending_launches[i][2])
			pending_launches.remove_at(i)


func _queue_batch() -> void:
	# All missiles share the same launch velocity — spread comes from guidance bias, not launch direction.
	var launch_vel: Vector3 = station.fetch_velocity(SimTime.t) + global_transform.basis.y * kickoff_velocity
	for i in range(batch_size):
		pending_launches.append([stagger_time * i, launch_vel, _random_lateral_bias()])


func _random_lateral_bias() -> Vector3:
	# Random unit vector perpendicular to the launch axis, scaled to bias_magnitude.
	# Perpendicular projection ensures the bias is purely lateral at launch.
	var up: Vector3 = global_transform.basis.y
	var rand_vec := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	var lateral := rand_vec - rand_vec.dot(up) * up
	if lateral.length_squared() < 1e-6:
		lateral = global_transform.basis.x  # degenerate fallback (essentially impossible)
	return lateral.normalized() * bias_magnitude


func _launch(launch_vel: Vector3, bias: Vector3) -> void:
	var spawn_pos: Vector3 = station.fetch(SimTime.t) + global_transform.basis * position
	var missile: Missile = missile_scene.instantiate()
	add_child(missile)
	missile.initialize(spawn_pos, launch_vel, global_transform.basis, bias)
