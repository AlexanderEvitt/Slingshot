extends Node3D

var plotter
var pointer
var planner

@export var plan : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	plotter = get_node("Plotter")
	pointer = get_node("Pointer")
	if plan:
		planner = get_node("Planner")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pointer.transform.basis = OwnShip.attitude
	position = OwnShip.position/1000
	
	plotter.positions = OwnShip.plotted_positions
	if plan:
		planner.positions = OwnShip.planned_positions
	
