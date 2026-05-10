class_name Explosion
extends MeshInstance3D

@export var flash_intensity := 0.1      # Peak multiplier
@export var decay_rate := 1.0           # Larger = faster decay

@onready var light: OmniLight3D = $OmniLight3D
@onready var pinprick: Pinprick = get_parent().get_node("Pinprick")

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
		light.visible = true
		if pinprick:
			pinprick.brightness = 10.0*current_intensity
	else:
		current_intensity = 0.0
		light.visible = false

func _apply_intensity() -> void:
	# Size sphere
	@warning_ignore("unsafe_property_access")
	mesh.radius = current_intensity
	@warning_ignore("unsafe_property_access")
	mesh.height = 2*mesh.radius
	# Set omni light brightness
	light.light_energy = 6.0*current_intensity/flash_intensity
