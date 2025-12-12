extends Node3D

# Sets the visibility if the viewport container is visible
func _process(_delta: float) -> void:
	visible = get_viewport().get_parent().is_visible_in_tree()
