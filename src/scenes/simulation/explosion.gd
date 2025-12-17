extends MeshInstance3D

@export var flash_intensity := 50.0      # Peak multiplier
@export var decay_rate := 1.0             # Larger = faster decay

var current_intensity := 0.0

func _process(delta):
	if Input.is_action_just_pressed("fire"):
		var delay = randf_range(0.0,10.0)
		await get_tree().create_timer(delay).timeout
		current_intensity = flash_intensity
	
	if current_intensity > 0.001:
		# Exponential decay
		current_intensity *= exp(-decay_rate * delta)
		_apply_intensity()
	else:
		current_intensity = 0.0

func _apply_intensity():
	# Size sphere
	mesh.radius = current_intensity
	mesh.height = 2*mesh.radius
