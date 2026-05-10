class_name Missile
extends Node3D

@export var navigation_constant: float = 4.0
@export var total_thrust: float = 0.098  # ~10g in km/s²
@export var detonation_radius: float = 1.0  # km
@export var max_lifetime_sim: float = 600.0

var system_position := Vector3.ZERO
var system_velocity := Vector3.ZERO
var sim_lifetime: float = 0.0

var flying: bool = true # true if flying, false if fixed (detonating)
var detonation_distance := Vector3.ZERO # where detonation occurs relative to player
@onready var explosion: Explosion = $Explosion


func initialize(spawn_pos: Vector3, spawn_vel: Vector3, _initial_attitude: Basis) -> void:
	system_position = spawn_pos
	system_velocity = spawn_vel
	print("Spawning...")
	_sync_scene_transform()


func _physics_process(delta: float) -> void:
	sim_lifetime += delta * SimTime.step
	if sim_lifetime > max_lifetime_sim:
		print("Freeing...")
		queue_free()
		return

	if flying:
		_integrate(_compute_thrust_vector(), delta)
		
		var target: PlayerShip = ShipData.player_ship
		if (global_position - target.global_position).length() <= detonation_radius:
			print("Detonating...")
			_detonate()
	else:
		# Fix in frame affixed to player ship
		global_position = detonation_distance + ShipData.player_ship.global_position
		


func _compute_thrust_vector() -> Vector3:
	var target: PlayerShip = ShipData.player_ship
	var r: Vector3 = target.system_position - system_position
	var range_km: float = r.length()

	if range_km < 0.001:
		return Vector3.ZERO

	var r_hat: Vector3 = r / range_km

	if system_velocity.length() < 0.001:
		return r_hat * total_thrust

	var v_rel: Vector3 = target.system_velocity - system_velocity
	var v_closing: float = maxf(-v_rel.dot(r_hat), 1.0)
	var omega: Vector3 = r.cross(v_rel) / (range_km * range_km)
	var a_pn: Vector3 = navigation_constant * v_closing * omega.cross(r_hat)
	var lat_mag: float = a_pn.length()

	if lat_mag >= total_thrust:
		return a_pn / lat_mag * total_thrust

	return a_pn + r_hat * sqrt(total_thrust * total_thrust - lat_mag * lat_mag)


func _integrate(acceleration: Vector3, delta: float) -> void:
	var dt: float = delta * SimTime.step
	system_velocity += acceleration * dt
	system_position += system_velocity * dt

	var spd: float = system_velocity.length()
	if spd > 0.001:
		var fwd := system_velocity / spd
		var up := Vector3.UP if abs(fwd.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var right := fwd.cross(up).normalized()
		global_transform.basis = Basis(right, right.cross(fwd).normalized(), -fwd)

	_sync_scene_transform()
	#print((global_position - ShipData.player_ship.global_position).length())


func _sync_scene_transform() -> void:
	global_transform.origin = system_position - ShipData.get_floating_frame_origin()


func _detonate() -> void:
	detonation_distance = global_position - ShipData.player_ship.global_position
	explosion.trigger()
	flying = false
	# Kill object after timer expires
	await get_tree().create_timer(1.0).timeout
	queue_free()


func fetch(_time: float) -> Vector3:
	return system_position
