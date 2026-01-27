extends Node3D

# Rotates station components to simulate gravity

@export var flip := 1
@export var ring_node : Node3D
@export var tunnel_node : Node3D
@export var frame_node : Node3D

var radius := 4500.0
var acc := 9.81

func _process(delta: float) -> void:
	var w := sqrt(acc/radius)
	
	var angle_step := flip*delta*SimTime.step*w
	ring_node.rotate_y(angle_step)
	tunnel_node.rotate_y(angle_step)
	frame_node.rotate_y(angle_step)
