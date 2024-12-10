extends Node3D

var plotter

# Called when the node enters the scene tree for the first time.
func _ready():
	plotter = get_node("CraftPlotter")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	transform.basis = OwnShip.attitude
	position = OwnShip.position/1000
	
	plotter.positions = OwnShip.plotted_positions
