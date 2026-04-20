class_name Explosion
extends MeshInstance3D

@export var flash_intensity := 0.1      # Peak multiplier
@export var decay_rate := 2.0           # Larger = faster decay

var current_intensity := 0.0

func _ready() -> void:
	_apply_intensity()

func trigger() -> void:
	current_intensity = flash_intensity

func _process(delta: float) -> void:
	if current_intensity > 0.00001:
		# Exponential decay
		current_intensity *= exp(-decay_rate * delta)
		_apply_intensity()
	else:
		current_intensity = 0.0

func _apply_intensity() -> void:
	# Size sphere
	@warning_ignore("unsafe_property_access")
	mesh.radius = current_intensity
	@warning_ignore("unsafe_property_access")
	mesh.height = 2*mesh.radius
