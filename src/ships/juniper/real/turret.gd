class_name PointDefenseCannon
extends Node3D

@export var cannon: Node3D
@export var elevation_min_deg: float = -10.0
@export var elevation_max_deg: float = 60.0
@export var slew_rate_deg: float = 90.0
@export var sensor_range_km: float = 100.0  # read by DefenseModule for threat assignment
@export var laser_range_km: float = 30.0
@export var laser_pulse_length: float = 0.1
@export var cooldown_time: float = 0.2
@export var left: bool = true

@onready var cooldown_timer: float = 1.0
@onready var beam: MeshInstance3D = cannon.get_node("Beam")
@onready var pinprick: Pinprick = cannon.get_node("Pinprick")

# Assigned each frame by DefenseModule; turret does not select its own target.
var assigned_target: Missile = null
var target_vector: Vector3
var az_current: float = 0.0
var el_current: float = 0.0


func _ready() -> void:
	# Deferred so PlayerShip's @onready vars (including defense_module) are set first.
	call_deferred("_register")


func _register() -> void:
	ShipData.player_ship.defense_module.register_turret(self)


func _physics_process(delta: float) -> void:
	if assigned_target == null:
		beam.visible = false
		pinprick.brightness = 0.0
		cooldown_timer -= SimTime.step * delta
	else:
		target_vector = assigned_target.system_position - ShipData.player_ship.system_position
		_point_at(target_vector.normalized(), delta)
		if _is_on_target() and cooldown_timer < 0.0 and _target_distance(assigned_target) < laser_range_km:
			_fire()
		else:
			beam.visible = false
			pinprick.brightness = 0.0
			cooldown_timer -= SimTime.step * delta


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
	return (cannon.global_transform.basis.x.normalized()).dot(target_vector.normalized()) > 0.999


func _fire() -> void:
	beam.visible = true
	pinprick.brightness = 1.0
	var current_target: Missile = assigned_target
	await get_tree().create_timer(laser_pulse_length).timeout
	current_target._detonate()
	cooldown_timer = 1.0


func _target_distance(missile: Missile) -> float:
	return (missile.system_position - ShipData.player_ship.system_position).length()
