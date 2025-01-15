extends Node3D

var chamber
var tail

# Called when the node enters the scene tree for the first time.
func _ready():
	tail = get_node("Tail")
	chamber = get_node("ThrustChamber")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if OwnShip.thrust > 0:
		visible = true
		tail.scale.x = OwnShip.thrust/0.05
	else:
		visible = false
