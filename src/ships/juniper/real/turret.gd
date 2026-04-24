class_name PointDefenseCannon
extends Node3D

@export var cannon: Node3D
@export var elevation_min_deg: float = -10.0
@export var elevation_max_deg: float = 60.0
@export var slew_rate_deg: float = 90.0
@export var laser_range_km: float = 30.0

@onready var beam: MeshInstance3D = cannon.get_node("Beam")

var target: Missile = null
var target_vector: Vector3
var az_current: float = 0.0
var el_current: float = 0.0


func _physics_process(delta: float) -> void:
	target = _find_nearest_missile()
	if target == null:
		target_vector = Vector3(1,0,0)
		_point_at(target_vector, delta)
		beam.visible = false
	else:
		target_vector = target.system_position - ShipData.player_ship.system_position
		_point_at(target_vector.normalized(), delta)
		if _is_on_target():
			_fire()
		else:
			beam.visible = false


func _point_at(offset: Vector3, delta: float) -> void:
	var local_target: Vector3 = (ShipData.player_ship.transform.basis.inverse() * offset).normalized()
	var pitch_yaw: Array[float] = _pitch_yaw_from_vector(local_target)

	var rate := deg_to_rad(slew_rate_deg)
	az_current += clamp(angle_difference(az_current, pitch_yaw[1]), -rate * delta, rate * delta)
	el_current += clamp(angle_difference(el_current, pitch_yaw[0]), -rate * delta, rate * delta)

	rotation.z = az_current
	cannon.rotation.y = clamp(el_current, deg_to_rad(elevation_min_deg), deg_to_rad(elevation_max_deg))


func _pitch_yaw_from_vector(t: Vector3) -> Array[float]:
	var pitch := -asin(t.z)
	var yaw := atan2(t.y, t.x)
	return [pitch, yaw]


func _is_on_target() -> bool:
	#print((cannon.global_transform.basis.x.normalized()).dot(target_vector.normalized()))
	return ((cannon.global_transform.basis.x.normalized()).dot(target_vector.normalized()) > 0.999)


func _fire() -> void:
	beam.visible = true
	target._detonate()


func _find_nearest_missile() -> Missile:
	var nearest: Missile = null
	var nearest_dist := INF
	for node in get_tree().get_nodes_in_group("missiles"):
		var missile := node as Missile
		if missile == null:
			continue
		var dist: float = (missile.system_position - ShipData.player_ship.system_position).length()
		if dist < nearest_dist and dist < 8.0:
			nearest_dist = dist
			nearest = missile
	return nearest
