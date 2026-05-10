class_name OrbitScene
extends Node3D

# Node reference to whatever orbit proxy is currently selected (null if nothing).
var selected_node: Node3D = null

@onready var cam: Camera3D = get_viewport().get_camera_3d()


func _ready() -> void:
	# Wire up click detectors for static BodyInheritor proxies already in the scene.
	var selectables: Array = get_tree().get_nodes_in_group("Selectable")
	for s: Area3D in selectables:
		var body: Node3D = s.get_parent() as Node3D
		s.input_event.connect(on_selected.bind(body))


func _process(_delta: float) -> void:
	position = position - cam.global_position  # keep orbit root near world origin


func on_selected(_camera: Camera3D, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int, node: Node3D) -> void:
	var mouse_click := event as InputEventMouseButton
	if mouse_click and mouse_click.button_index == 1 and mouse_click.pressed:
		selected_node = node
