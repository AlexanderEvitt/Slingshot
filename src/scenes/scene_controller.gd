extends Node3D

@export var planet_orbits : bool
@export var zoomable : bool

var selected_body = null

func _ready():
	# Connect the click detector signal
	var selectables = get_tree().get_nodes_in_group("Selectable")
	for s in selectables:
		var body_path = s.get_parent().body_path
		s.input_event.connect(on_selected.bind(body_path))

func _process(_delta):
	position = -ShipData.player_ship.position
	# Setting this root to the negative of the ship position ensures the cam is always at the global origin
	# Should not be necessary (and should have no effect) in a double precision build
	# But the atmosphere plugin needs this for some reason (jitters otherwise)

func on_selected(_camera, event, _click_position, _click_normal, _shape_idx, body_path):
	# Handles mouse clicking on selectable objects
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		selected_body = body_path
