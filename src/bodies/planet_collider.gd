extends StaticBody3D

var prev_pos = Vector3(0,0,0)

func _phsyics_process(delta: float) -> void:
	constant_linear_velocity = (global_position - prev_pos)/delta
	prev_pos = global_position
