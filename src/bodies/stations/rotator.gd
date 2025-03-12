extends MeshInstance3D

@export var flip = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(2*PI*flip*delta*SystemTime.step/(4*60))
