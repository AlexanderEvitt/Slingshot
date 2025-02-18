extends Node3D

var plotter
var pointer
var planner

var scaledown = 1

@export var plan : bool
@export var smashed : bool
@export var camera_mode : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	plotter = get_node("Plotter")
	pointer = get_node("Pointer")
	if plan:
		planner = get_node("Planner")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Use camera mode to determine whether camera is included in rotation
	if camera_mode:
		pointer.transform.basis = OwnShip.attitude
	else:
		transform.basis = OwnShip.attitude
		plotter.transform.basis = OwnShip.attitude.inverse() # plotter needs to stay in the right frame
	position = OwnShip.position/scaledown
	if smashed:
		position.z = 0
	
	plotter.positions = OwnShip.plotted_positions
	if plan:
		planner.positions = OwnShip.planned_positions
	
