extends Node

var position
var velocity
var attitude
var thrust
var torque = Vector3(0,0,0)

var plotted_positions
var planned_positions

var ship
var propagator

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if ship != null:
		# Only start assigning after ship is defined
		# ship is set by the ships_handler
		position = ship.position
		velocity = ship.velocity
		attitude = ship.attitude
		thrust = ship.thrust
		torque = ship.torque
		
		plotted_positions = propagator.plotted_positions
		planned_positions = propagator.passed_planned_positions
