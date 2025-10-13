extends Node3D

@export var up : bool
@export var down : bool
@export var left : bool
@export var right : bool
@export var roll_left : bool
@export var roll_right : bool

var cutoff = 0.1
var torque

var my_torque = 0
var my_thrust = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Start as invisible, make visible if firing
	visible = false
	
	record_torque()
	record_thrusters()
	make_thruster_fire()

func record_torque():
	# Record commanded torque
	torque = ShipData.player_ship.torque
	if torque == null:
		torque = Vector3(0,0,0)
	torque = ShipData.player_ship.attitude.inverse()*torque
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

func record_thrusters():
	# Record translational thruster firings
	var thrusters = ShipData.player_ship.thrust - ShipData.player_ship.propulsion_calculator.main_thrust*Vector3(1,0,0)
	if thrusters.length() < 0.001:
		my_thrust = 0
	else:
		var my_thrust_vector = transform.basis.y
		my_thrust = thrusters.dot(my_thrust_vector)/thrusters.length()
		my_thrust = clamp(-my_thrust,0,1)
	
func make_thruster_fire():
	# Turn on thruster
	var fire = (my_torque + 0.5*my_thrust)

	var unit = 150*Vector3(1,1,1)
	if fire > cutoff:
		visible = true
		scale = fire*unit
