extends Node

var position
var velocity
var attitude

var ship

# Called when the node enters the scene tree for the first time.
func _ready():
	ship = get_node("/root/GameRoot/Ships/OwnShip")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = ship.position
	velocity = ship.velocity
	attitude = ship.attitude
