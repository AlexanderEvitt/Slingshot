extends Node3D

@export var up : bool
@export var down : bool
@export var left : bool
@export var right : bool
@export var roll_left : bool
@export var roll_right : bool

var cutoff = 0.01
var torque


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	visible = false
	torque = OwnShip.torque
	
	var thrusters = OwnShip.thrust - OwnShip.throttle*Vector3(1,0,0)
	var my_thrust_vector = transform.basis.y
	# For some reason flip the fore/aft thrusters
	if abs(my_thrust_vector.x) == 1:
		my_thrust_vector.x = -my_thrust_vector.x
	var likeness = thrusters.dot(my_thrust_vector)
	likeness = clamp(likeness,0,1)
	
	if torque == null:
		torque = Vector3(0,0,0)
		
	# Place in ship frame
	torque = OwnShip.attitude.inverse()*torque
	var total_torque = 0
	if up:
		total_torque = total_torque + (torque.z)
	if down:
		total_torque = total_torque + (-torque.z)
	if left:
		total_torque = total_torque + (torque.y)
	if right:
		total_torque = total_torque + (-torque.y)
	if roll_left:
		total_torque = total_torque + (-torque.x)
	if roll_right:
		total_torque = total_torque + (torque.x)
		
	call_thruster(total_torque + likeness)
			
func call_thruster(t):
	var unit = 200*Vector3(1,1,1)
	if t > cutoff:
		visible = true
		scale = sqrt(abs(t))*unit
