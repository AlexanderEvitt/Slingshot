extends Node3D

@onready var viewport_parent: Control = get_viewport().get_parent()

func _process(_delta: float) -> void:
	visible = viewport_parent.is_visible_in_tree()
