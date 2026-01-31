class_name PlayerCharacter
extends Node3D

@export var mouse_sensitivity := 0.0025
@export var pitch_limit := 89.0
@export var look_distance := 5.0
@export var move_speed := 3.0
@export var focus_offset := Vector3(0, 1, 0) # offset relative to collider

@export var seats: Array[Vector3] = [Vector3(-0.732,-1.107,-2.191)]
var seat := 0

@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $RayCast3D
@onready var crosshair: Control = $Camera3D/Crosshair
@onready var pause_menu: Control = $Camera3D/PauseMenu

var yaw := 0.0
var pitch := 0.0

var in_transition := false
var seated := false
var focusing := false
var transition_t := 0.0
var start_transform: Transform3D # transform before going to focus mode
var target_transform: Transform3D # transform being lerped to

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if in_transition:
		return # Ignore input while transitioning

	# Move camera with mouse motion
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion_event := event as InputEventMouseMotion
		yaw -= motion_event.relative.x * mouse_sensitivity
		pitch -= motion_event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))
		rotation.y = yaw
		rotation.x = pitch

	# Go into our out of focus mode (focus on display)
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed:
			match key_event.keycode:
				KEY_ESCAPE:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				KEY_F:
					_on_interact()
					
	if Input.is_action_just_pressed("next_seat") and !focusing and !in_transition:
		seat = (seat + 1) % (len(seats))
		position = seats[seat]
		

# Move to display
func _on_interact() -> void:
	if not focusing:
		# Try to find what the camera is looking at
		raycast.enabled = true
		if raycast.is_colliding():
			var collider: Node3D = raycast.get_collider()
			if collider:
				# Current camera transform
				start_transform = camera.global_transform
				# Get new transform
				var collider_transform: Transform3D = collider.global_transform
				var offset_position: Vector3 = collider_transform.origin + (collider_transform.basis * focus_offset)
				# Orientation that looks at the display (rotated by -90 about x)
				var looking_basis: Basis = Basis(collider_transform.basis.x,-PI/2) * collider_transform.basis
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
		var t := clampf(transition_t, 0.0, 1.0)
		camera.global_transform = camera.global_transform.interpolate_with(target_transform, t)

		if t >= 1.0:
			in_transition = false
