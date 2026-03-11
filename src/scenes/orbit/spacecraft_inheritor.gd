extends Node3D

@onready var pointer: Node3D = $Pointer
@onready var plotter: Plotter = ShipData.player_ship.plotter

@export var body_path : String

# Checking this determines whether position is set locally or globally
# See orbit_scene_controller and external_scene_controller
@export var local_positioning := false

func _ready() -> void:
	# Only assign plotter if it exists to avoid error
	if has_node("Plotter"):
		plotter = $Plotter

func _process(_delta: float) -> void:
	pointer.transform.basis = ShipData.player_ship.attitude
	
	if local_positioning:
		position = ShipData.player_ship.system_position
	else:
		global_position = ShipData.player_ship.global_position
	
	if plotter:
		plotter.positions = ShipData.player_ship.propagate_module.get("plotted_positions")
