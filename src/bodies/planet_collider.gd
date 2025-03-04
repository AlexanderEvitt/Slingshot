extends StaticBody3D

var prev_pos = Vector3(0,0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	constant_linear_velocity = global_position - prev_pos
	prev_pos = global_position
