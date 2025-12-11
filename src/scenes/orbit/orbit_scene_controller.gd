extends Node3D

# Expose what body is selected to navigation
var selected_body = null

# Get reference to camera
@onready var cam = get_viewport().get_camera_3d()

func _ready():
	# Connect the click detector signal
	var selectables = get_tree().get_nodes_in_group("Selectable")
	for s in selectables:
		var body_path = s.get_parent().body_path
		s.input_event.connect(on_selected.bind(body_path))

func _process(_delta):
	position = (position - cam.global_position)
	# Setting this root to the negative of the camera position ensures the cam is always near the global origin

func on_selected(_camera, event, _click_position, _click_normal, _shape_idx, body_path):
	# Handles mouse clicking on selectable objects
	var mouse_click = event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		selected_body = body_path
