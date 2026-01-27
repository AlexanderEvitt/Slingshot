class_name OrbitScene
extends Node3D

# Expose what body is selected to navigation
var selected_body: String = ""

# Get reference to camera
@onready var cam: Camera3D = get_viewport().get_camera_3d()

func _ready() -> void:
	# Connect the click detector signal
	var selectables: Array = get_tree().get_nodes_in_group("Selectable")
	for s: Area3D in selectables:
		var body_path: String = s.get_parent().get("body_path")
		s.input_event.connect(on_selected.bind(body_path))

func _process(_delta: float) -> void:
	position = (position - cam.global_position)
	# Setting this root to the negative of the camera position ensures the cam is always near the global origin

func on_selected(_camera: Camera3D, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int, body_path: String) -> void:
	# Handles mouse clicking on selectable objects
	var mouse_click := event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		selected_body = body_path
