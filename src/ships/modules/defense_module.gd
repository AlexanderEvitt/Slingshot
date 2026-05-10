class_name DefenseModule
extends Node3D

# All active (non-detonating) missiles, refreshed every physics tick.
var active_threats: Array[Missile] = []

# Turrets registered via register_turret(); targets assigned to each every tick.
var turrets: Array[PointDefenseCannon] = []


# Called by each turret in its deferred _ready so the full scene tree is initialised first.
func register_turret(turret: PointDefenseCannon) -> void:
	turrets.append(turret)


func _physics_process(_delta: float) -> void:
	_refresh_threats()
	_assign_targets()


func _refresh_threats() -> void:
	active_threats.clear()
	for node: Node in get_tree().get_nodes_in_group("missiles"):
		var missile := node as Missile
		# INERT and GUIDING missiles are live threats; skip DETONATING.
		if missile != null and missile.state != Missile.State.DETONATING:
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
