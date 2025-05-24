extends Node

var position
var velocity
var attitude
var thrust
var torque = Vector3(0,0,0)
var throttle = 0

var plotted_positions
var planned_positions

var player_ship
var propagator

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player_ship != null:
		# Only start assigning after ship is defined
		# ship is set by the ships_handler
		position = player_ship.position
		velocity = player_ship.velocity
		attitude = player_ship.attitude
		thrust = player_ship.thrust
		torque = player_ship.torque
		throttle = player_ship.throttle
		
		plotted_positions = propagator.plotted_positions
		planned_positions = propagator.passed_planned_positions
