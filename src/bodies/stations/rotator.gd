extends Node3D

@export var flip = 1
@export var ring_node : Node3D
@export var tunnel_node : Node3D
@export var frame_node : Node3D

func _process(delta: float) -> void:
	var radius = 4500
	var acc = 9.81
	var w = sqrt(acc/radius)
	
	var angle_step = flip*delta*SystemTime.step*w
	ring_node.rotate_y(angle_step)
	tunnel_node.rotate_y(angle_step)
	frame_node.rotate_y(angle_step)
