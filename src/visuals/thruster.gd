extends Node3D

@export var up : bool
@export var down : bool
@export var left : bool
@export var right : bool
@export var roll_left : bool
@export var roll_right : bool

var cutoff := 0.01
var torque: Vector3
var max_torque: float
var max_thrust: float 

@onready var light: OmniLight3D = $OmniLight3D

var my_torque := 0.0
var my_thrust := 0.0

func _ready() -> void:
	call_deferred("get_max_values")

func get_max_values() -> void:
	max_torque = ShipData.player_ship.attitude_module.max_torque
	max_thrust = ShipData.player_ship.propulsion_module.thruster_force
	
func _physics_process(_delta: float) -> void:
	# Start as invisible, make visible if firing
	visible = false
	
	if SimTime.step == 1:
		record_torque()
		record_thrusters()
		make_thruster_fire()

func record_torque() -> void:
	# Record commanded torque
	torque = ShipData.player_ship.torque
	if torque == null:
		torque = Vector3(0,0,0)
	torque = ShipData.player_ship.transform.basis.inverse()*torque
	my_torque = 0
	if up:
		my_torque = my_torque + (torque.z)
	if down:
		my_torque = my_torque + (-torque.z)
	if left:
		my_torque = my_torque + (torque.y)
	if right:
		my_torque = my_torque + (-torque.y)
	if roll_left:
		my_torque = my_torque + (-torque.x)
	if roll_right:
		my_torque = my_torque + (torque.x)

func record_thrusters() -> void:
	# Record translational thruster firings
	var thrusters: Vector3 = ShipData.player_ship.propulsion_module.thrust - ShipData.player_ship.propulsion_module.main_thrust*Vector3(1,0,0)
	if thrusters.length() < 0.001:
		my_thrust = 0
	else:
		var my_thrust_vector: Vector3 = transform.basis.y
		my_thrust = -thrusters.dot(my_thrust_vector)
	
func make_thruster_fire() -> void:
	# Turn on thruster
	var torque_amount := my_torque / max_torque
	var thrust_amount := my_thrust / max_thrust
	var fire: float = clamp(torque_amount + thrust_amount, 0.0, 1.0)

	if fire > cutoff:
		visible = true
		light.light_energy = 0.1*fire
		scale = fire*Vector3.ONE
