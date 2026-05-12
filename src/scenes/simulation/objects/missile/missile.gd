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

# The node this missile is homing on. Defaults to the player ship for enemy missiles;
# set to a Missile for interceptors. Must expose system_position and system_velocity.
var target: Node3D = null

# false = enemy missile (counted as a threat by DefenseModule)
# true  = player-fired interceptor (ignored by DefenseModule threat scan)
var friendly: bool = false

var state: State = State.INERT
var armed: bool = false  # true once target first starts closing

signal detonated  # emitted the moment detonation begins; proxies listen to trigger their own effects
var _detonation_offset := Vector3.ZERO  # scene-space offset from player ship at moment of detonation
@onready var explosion: Explosion = $Explosion
@onready var _mesh: Node3D = $Mesh

const ORBIT_PROXY: PackedScene = preload("res://scenes/simulation/objects/missile/missile_proxy.tscn")


func _ready() -> void:
	add_to_group("Dynamic")
	add_to_group("missiles")  # all missiles; DefenseModule filters by friendly flag


func get_orbit_rep() -> PackedScene:
	return ORBIT_PROXY


func initialize(spawn_pos: Vector3, spawn_vel: Vector3, _initial_attitude: Basis, bias: Vector3 = Vector3.ZERO, p_target: Node3D = null) -> void:
	system_position = spawn_pos
	system_velocity = spawn_vel
	bias_acceleration = bias
	target = p_target if p_target != null else ShipData.player_ship
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
			_orient_mesh(system_velocity)    # point along travel direction while coasting

		State.GUIDING:
			# If the target was destroyed before we reached it, detonate in place.
			if not is_instance_valid(target):
				_detonate()
				return

			var r: Vector3 = _target_position() - system_position
			var range_km: float = r.length()
			var r_hat: Vector3 = r / maxf(range_km, 0.001)
			var v_rel: Vector3 = _target_velocity() - system_velocity
			var v_closing: float = -v_rel.dot(r_hat)  # positive = closing, negative = opening

			# Arm once the missile first starts closing on the target.
			if not armed and v_closing > 0.0:
				armed = true

			if armed and (range_km <= detonation_radius or v_closing < 0.0):
				_detonate()
				return

			var thrust: Vector3 = _compute_thrust_vector()
			_integrate(thrust, delta)
			_orient_mesh(thrust)  # point -Z along thrust vector

		State.DETONATING:
			# Hold position in the frame of the player ship so the explosion
			# stays visually anchored regardless of the ship's inertial velocity.
			global_position = ShipData.player_ship.global_position + _detonation_offset
			system_position = ShipData.player_ship.system_position + _detonation_offset


func _compute_thrust_vector() -> Vector3:
	var r: Vector3 = _target_position() - system_position
	var range_km: float = r.length()

	if range_km < 0.001:
		return Vector3.ZERO

	var r_hat: Vector3 = r / range_km

	if system_velocity.length() < 0.001:
		return r_hat * total_thrust

	var v_rel: Vector3 = _target_velocity() - system_velocity
	var v_closing: float = maxf(-v_rel.dot(r_hat), 1.0)  # clamped to avoid PN singularity at rest
	var omega: Vector3 = r.cross(v_rel) / (range_km * range_km)
	var a_pn: Vector3 = navigation_constant * v_closing * omega.cross(r_hat)
	var a_cmd: Vector3 = a_pn + bias_acceleration  # lateral bias forces a unique approach angle
	var cmd_mag: float = a_cmd.length()

	if cmd_mag >= total_thrust:
		return a_cmd / cmd_mag * total_thrust

	# Use remaining thrust budget to accelerate along the LOS toward the target.
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


func _orient_mesh(direction: Vector3) -> void:
	if _mesh == null or direction.length_squared() < 0.000001:
		return
	var dir: Vector3 = direction.normalized()
	var up: Vector3 = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	_mesh.look_at(_mesh.global_position + dir, up)


func _detonate() -> void:
	state = State.DETONATING
	_detonation_offset = global_position - ShipData.player_ship.global_position
	# Interceptors: if the target missile is within kill radius, detonate it too.
	if friendly and is_instance_valid(target):
		var target_missile := target as Missile
		if target_missile != null and target_missile.state != State.DETONATING:
			if (target_missile.system_position - system_position).length() <= detonation_radius:
				target_missile._detonate()
	explosion.trigger()
	detonated.emit()
	await get_tree().create_timer(1.0).timeout
	queue_free()


func fetch(_time: float) -> Vector3:
	return system_position


# Read system_position/system_velocity off any Node3D that exposes them.
# Both PlayerShip and Missile do; warning suppression is intentional duck-typing.
func _target_position() -> Vector3:
	@warning_ignore("unsafe_property_access")
	return target.system_position


func _target_velocity() -> Vector3:
	@warning_ignore("unsafe_property_access")
	return target.system_velocity
