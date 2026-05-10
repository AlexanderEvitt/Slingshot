class_name Missile
extends Node3D

enum State { INERT, GUIDING, DETONATING }

@export var navigation_constant: float = 4.0
@export var total_thrust: float = 0.098  # ~10g in km/s²
@export var detonation_radius: float = 1.0  # km
@export var max_lifetime_sim: float = 600.0
@export var coast_time: float = 2.0  # sim-seconds before motor ignites

var system_position := Vector3.ZERO
var system_velocity := Vector3.ZERO
var bias_acceleration := Vector3.ZERO  # constant lateral bias set at launch
var sim_lifetime: float = 0.0
var coast_elapsed: float = 0.0

var state: State = State.INERT
var armed: bool = false  # true once target first starts closing
var detonation_distance := Vector3.ZERO  # detonation position relative to player
@onready var explosion: Explosion = $Explosion


func initialize(spawn_pos: Vector3, spawn_vel: Vector3, _initial_attitude: Basis, bias: Vector3 = Vector3.ZERO) -> void:
	system_position = spawn_pos
	system_velocity = spawn_vel
	bias_acceleration = bias
	_sync_scene_transform()


func _physics_process(delta: float) -> void:
	var sim_dt: float = delta * SimTime.step
	sim_lifetime += sim_dt
	if sim_lifetime > max_lifetime_sim:
		queue_free()
		return

	match state:
		State.INERT:
			coast_elapsed += sim_dt
			if coast_elapsed >= coast_time:
				state = State.GUIDING
			_integrate(Vector3.ZERO, delta)  # coast on initial velocity

		State.GUIDING:
			var target: PlayerShip = ShipData.player_ship
			var r: Vector3 = target.system_position - system_position
			var range_km: float = r.length()
			var r_hat: Vector3 = r / maxf(range_km, 0.001)
			var v_rel: Vector3 = target.system_velocity - system_velocity
			var v_closing: float = -v_rel.dot(r_hat)  # positive = closing, negative = opening

			# Arm once the missile first starts closing on the target
			if not armed and v_closing > 0.0:
				armed = true

			if armed and (range_km <= detonation_radius or v_closing < 0.0):
				_detonate()
				return

			_integrate(_compute_thrust_vector(), delta)

		State.DETONATING:
			# Fix position in the frame affixed to the player ship
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
	var v_closing: float = maxf(-v_rel.dot(r_hat), 1.0)  # clamped to avoid PN singularity at rest
	var omega: Vector3 = r.cross(v_rel) / (range_km * range_km)
	var a_pn: Vector3 = navigation_constant * v_closing * omega.cross(r_hat)
	var a_cmd: Vector3 = a_pn + bias_acceleration  # lateral bias forces a unique approach angle
	var cmd_mag: float = a_cmd.length()

	if cmd_mag >= total_thrust:
		return a_cmd / cmd_mag * total_thrust

	# Use remaining thrust budget to accelerate along the LOS toward the target
	return a_cmd + r_hat * sqrt(total_thrust * total_thrust - cmd_mag * cmd_mag)


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


func _sync_scene_transform() -> void:
	global_transform.origin = system_position - ShipData.get_floating_frame_origin()


func _detonate() -> void:
	state = State.DETONATING
	detonation_distance = global_position - ShipData.player_ship.global_position
	explosion.trigger()
	await get_tree().create_timer(1.0).timeout
	queue_free()


func fetch(_time: float) -> Vector3:
	return system_position
