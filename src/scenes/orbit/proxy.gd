class_name Proxy
extends Node3D

# The simulation object this proxy represents. Typed as Node here;
# subclasses shadow this with the specific sim type they expect.
var sim_object: Node = null


func set_sim_object(node: Node) -> void:
	sim_object = node


func _process(_delta: float) -> void:
	if not is_instance_valid(sim_object):
		return  # dynamic.gd owns the lifecycle and will cull this proxy
	_sync()


# Override in subclasses to update position, attitude, and visuals each frame.
func _sync() -> void:
	pass
