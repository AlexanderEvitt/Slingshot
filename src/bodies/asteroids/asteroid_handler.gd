@tool
extends Node3D

var body

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body = get_node("Icosphere")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	body.rotation.y = body.rotation.y + 0.005
