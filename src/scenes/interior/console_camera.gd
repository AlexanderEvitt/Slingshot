extends Node3D

@export var mouse_sensitivity := 0.0025
@export var pitch_limit := 89.0
@export var look_distance := 5.0
@export var move_speed := 3.0
@export var focus_offset := Vector3(0, 1, 0) # offset relative to collider

@onready var camera = $Camera3D
@onready var raycast = $RayCast3D
@onready var crosshair = $Camera3D/Crosshair
@onready var pause_menu := $Camera3D/PauseMenu

var yaw := 0.0
var pitch := 0.0

var in_transition := false
var seated := false
var focusing := false
var transition_t := 0.0
var start_transform: Transform3D
var target_transform: Transform3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if in_transition:
		return # Ignore input while transitioning

	# Move camera with mouse motion
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))
		rotation.y = yaw
		rotation.x = pitch

	# Go into our out of focus mode (focus on display)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			KEY_F:
				_on_interact()

# Move to display
func _on_interact() -> void:
	if not focusing:
		# Try to find what the camera is looking at
		raycast.enabled = true
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider:
				# Current camera transform
				start_transform = camera.global_transform
				# Get new transform
				var collider_transform = collider.global_transform
				var offset_position = collider_transform.origin + (collider_transform.basis * focus_offset)
				# Orientation that looks at the display (rotated by -90 about x)
				var looking_basis = Basis(Vector3(1,0,0),-PI/2) * collider_transform.basis
				target_transform = Transform3D(looking_basis, offset_position)
				focusing = true
				in_transition = true
				transition_t = 0.0
				# Mouse visible, cross hair not
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				crosshair.visible = false
	else:
		# Return to original position
		start_transform = camera.global_transform
		target_transform = global_transform * Transform3D.IDENTITY # reset to camera's default local zero
		focusing = false
		in_transition = true
		transition_t = 0.0
		# Mouse invisible, cross hair visible
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		crosshair.visible = true

func _physics_process(delta: float) -> void:
	if in_transition:
		transition_t += delta * move_speed
		var t = clamp(transition_t, 0.0, 1.0)
		camera.global_transform = camera.global_transform.interpolate_with(target_transform, t)

		if t >= 1.0:
			in_transition = false
