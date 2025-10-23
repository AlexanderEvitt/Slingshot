extends Node3D

var plotter
var pointer


@export var plan : bool
@export var camera_mode : bool

var body_path = "Ships/PlayerShip" # Needed to access data for selecting it

# Called when the node enters the scene tree for the first time.
func _ready():
	plotter = get_node("Plotter")
	pointer = get_node("Pointer")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Use camera mode to determine whether camera is included in rotation
	if true:
		pointer.transform.basis = ShipData.player_ship.attitude
	else:
		transform.basis = ShipData.player_ship.attitude
		plotter.transform.basis = ShipData.player_ship.attitude.inverse() # plotter needs to stay in the right frame
	position = ShipData.player_ship.position
	
	plotter.positions = ShipData.propagator.plotted_positions
