extends Node

var position
var velocity
var attitude

var plotted_positions = [Vector3(0,0,0),Vector3(0,0,0)]

var ship

# Called when the node enters the scene tree for the first time.
func _ready():
	ship = get_node("/root/GameRoot/Ships/OwnShip")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = ship.position
	velocity = ship.velocity
	attitude = ship.attitude
	
	plotted_positions = ship.get_node("Propagator").plotted_positions
