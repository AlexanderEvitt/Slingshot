extends Node3D

var plotter
var pointer

# Called when the node enters the scene tree for the first time.
func _ready():
	plotter = get_node("CraftPlotter")
	pointer = get_node("Pointer")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pointer.transform.basis = OwnShip.attitude
	position = OwnShip.position/1000
	
	plotter.positions = OwnShip.plotted_positions
