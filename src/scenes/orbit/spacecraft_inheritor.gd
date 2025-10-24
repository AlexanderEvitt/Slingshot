extends Node3D

@onready var plotter = $Plotter
@onready var pointer = $Pointer

@export var body_path : String

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Use camera mode to determine whether camera is included in rotation
	pointer.transform.basis = ShipData.player_ship.attitude
	position = ShipData.player_ship.position
	
	plotter.positions = ShipData.player_ship.propagator.plotted_positions
