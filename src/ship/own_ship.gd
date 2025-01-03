extends Node

var position
var velocity
var attitude
var thrust

var propagator

var plotted_positions = [Vector3(0,0,0),Vector3(0,0,0)]
var planned_positions = [Vector3(0,0,0),Vector3(0,0,0)]

var ship

# Called when the node enters the scene tree for the first time.
func _ready():
	ship = get_node("/root/GameRoot/Ships/OwnShip")
	propagator = ship.get_node("Propagator")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = ship.position
	velocity = ship.velocity
	attitude = ship.attitude
	thrust = ship.thrust
	
	plotted_positions = propagator.plotted_positions
	planned_positions = propagator.passed_planned_positions
