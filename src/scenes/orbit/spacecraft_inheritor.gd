extends Node3D

var plotter
@onready var pointer = $Pointer

@export var body_path : String

# Checking this determines whether position is set locally or globally
# See orbit_scene_controller and external_scene_controller
@export var local_positioning = false

func _ready():
	# Only assign plotter if it exists to avoid error
	if has_node("Plotter"):
		plotter = $Plotter

func _process(_delta):
	# Use camera mode to determine whether camera is included in rotation
	pointer.transform.basis = ShipData.player_ship.attitude
	
	if local_positioning:
		position = ShipData.player_ship.position
	else:
		global_position = ShipData.player_ship.global_position
	
	if plotter:
		plotter.positions = ShipData.player_ship.propagator.plotted_positions
