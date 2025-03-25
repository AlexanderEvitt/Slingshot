extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = get_viewport().get_child(0).hud_enable
