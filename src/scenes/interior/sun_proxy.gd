extends DirectionalLight3D

func _process(_delta: float) -> void:
	global_transform.basis = ShipData.sun_angle
