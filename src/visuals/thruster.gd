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
	
	if torque == null:
		torque = Vector3(0,0,0)
	
	if up:
		call_thruster(torque.z)
	if down:
		call_thruster(-torque.z)
	if left:
		call_thruster(torque.y)
	if right:
		call_thruster(-torque.y)
	if roll_left:
		call_thruster(-torque.x)
	if roll_right:
		call_thruster(torque.x)
			
func call_thruster(t):
	var unit = 2*Vector3(1,1,1)
	if t > cutoff:
		visible = true
		#scale = sqrt(abs(t))*unit
