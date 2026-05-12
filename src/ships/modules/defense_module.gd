class_name DefenseModule
extends Node3D

# All active (non-detonating) hostile missiles, refreshed every physics tick.
var active_threats: Array[Missile] = []

# Turrets registered via register_turret(); targets assigned to each every tick.
var turrets: Array[PointDefenseCannon] = []

@export var missile_scene: PackedScene
@export var interceptor_range_km: float = 100.0  # don't launch beyond this range
@export var fire_rate: float = 3.0               # minimum sim-seconds between launches

@export_group("Interceptor Parameters")
@export var interceptor_thrust: float = 0.1      # km/s² — needs to catch a fast target
@export var interceptor_detonation_radius: float = 0.5
@export var interceptor_coast_time: float = 0.0  # sim-seconds before motor ignites
@export var interceptor_lifetime: float = 120.0  # sim-seconds before self-destruct
@export var interceptor_launch_speed: float = 0.01 # km/s nudge along ship forward at launch

# Tracks which interceptor (value) is assigned to each threat (key).
# Untyped: typed dict validates freed instances on key iteration and throws.
var _interceptors: Dictionary = {}
var _fire_cooldown: float = 0.0


# Called by each turret in its deferred _ready so the full scene tree is initialised first.
func register_turret(turret: PointDefenseCannon) -> void:
	turrets.append(turret)


func _physics_process(delta: float) -> void:
	var sim_dt: float = delta * SimTime.step
	_refresh_threats()
	_assign_targets()
	_fire_interceptors(sim_dt)


func _refresh_threats() -> void:
	active_threats.clear()
	for node: Node in get_tree().get_nodes_in_group("missiles"):
		var missile := node as Missile
		# Hostile, non-detonating missiles only.
		if missile != null and not missile.friendly and missile.state != Missile.State.DETONATING:
			active_threats.append(missile)


func _assign_targets() -> void:
	var ship_pos: Vector3 = ShipData.player_ship.system_position

	# Pre-compute distances once, then sort nearest-first (closest = highest priority).
	var threats_with_dist: Array = []
	for missile: Missile in active_threats:
		threats_with_dist.append({ "missile": missile, "dist": (missile.system_position - ship_pos).length() })
	threats_with_dist.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.dist < b.dist
	)

	# Greedy assignment: each turret claims the nearest unclaimed threat in its sensor range.
	var claimed: Array[Missile] = []
	for turret: PointDefenseCannon in turrets:
		turret.assigned_target = null
		for entry: Dictionary in threats_with_dist:
			var missile: Missile = entry.missile
			if missile in claimed:
				continue
			if entry.dist <= turret.sensor_range_km:
				turret.assigned_target = missile
				claimed.append(missile)
				break


func _fire_interceptors(sim_dt: float) -> void:
	if missile_scene == null:
		return

	_fire_cooldown = maxf(0.0, _fire_cooldown - sim_dt)

	# Prune entries where the threat or its interceptor is no longer alive.
	# Check validity before casting — casting a freed object throws unconditionally.
	var stale: Array = []
	for threat in _interceptors.keys():
		var raw: Variant = _interceptors[threat]
		if not is_instance_valid(threat) or not is_instance_valid(raw):
			stale.append(threat)
	for threat in stale:
		_interceptors.erase(threat)

	if _fire_cooldown > 0.0:
		return

	# Launch one interceptor per cooldown window at the nearest unassigned threat in range.
	var ship_pos: Vector3 = ShipData.player_ship.system_position
	for threat: Missile in active_threats:
		if _interceptors.has(threat):
			continue  # already have one on the way
		if (threat.system_position - ship_pos).length() > interceptor_range_km:
			continue
		var interceptor: Missile = _launch_interceptor(threat)
		if interceptor != null:
			_interceptors[threat] = interceptor
			_fire_cooldown = fire_rate
		break  # one launch per cooldown window


func _launch_interceptor(threat: Missile) -> Missile:
	var interceptor: Missile = missile_scene.instantiate() as Missile
	if interceptor == null:
		push_error("DefenseModule: missile_scene root does not extend Missile.")
		return null

	# Apply interceptor parameters before add_child so _ready() sees the final values.
	interceptor.friendly = true
	interceptor.total_thrust = interceptor_thrust
	interceptor.detonation_radius = interceptor_detonation_radius
	interceptor.coast_time = interceptor_coast_time
	interceptor.max_lifetime_sim = interceptor_lifetime

	ShipData.sim_root.get_node("Dynamic").add_child(interceptor)

	# Derive spawn_pos from the ship's current scene-space position rather than
	# system_position.  system_position is written in _integrate_forces using
	# get_floating_frame_origin() at that SimTime.t; by the time _physics_process
	# runs SimTime.t may have advanced, so the round-trip in _sync_scene_transform
	# (system_pos - get_floating_frame_origin()) would drift by
	# floating_frame_velocity × ΔSimTime.t — visible at high warp.
	# Computing from global_position here means both sides of the conversion use
	# the same floating-frame snapshot and the drift cancels exactly.
	var spawn_pos: Vector3 = ShipData.player_ship.global_position + ShipData.get_floating_frame_origin()
	var launch_vel: Vector3 = ShipData.player_ship.system_velocity + (ShipData.player_ship.attitude.x * interceptor_launch_speed)
	interceptor.initialize(
		spawn_pos,
		launch_vel,
		ShipData.player_ship.attitude,
		Vector3.ZERO,
		threat
	)
	return interceptor
