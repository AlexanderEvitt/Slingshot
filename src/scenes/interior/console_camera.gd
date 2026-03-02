class_name PlayerCharacter
extends Node3D

@export var mouse_sensitivity := 0.0025
@export var pitch_limit := 89.0
@export var look_distance := 5.0
@export var move_speed := 3.0
@export var focus_offset := Vector3(0, 1, 0) # offset relative to collider

# Get children nodes
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $RayCast3D
@onready var crosshair: Control = $Head/Camera3D/Crosshair
@onready var pause_menu: Control = $Head/Camera3D/PauseMenu
@onready var background: MeshInstance3D = $Head/Camera3D/Background

# Get the viewport that sees the simulation (should be a sibling)
@onready var sim_viewport: SubViewport = get_parent().get_node("SimViewport")

# Get the list of nodes that the player can snap to
# This is assigned by the interior model loader
@onready var viewpoints: Array[Node]
var seat := 0 # which viewpoint you're attached to

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
	
	# Assign viewport texture to background
	var background_material: StandardMaterial3D = background.get_active_material(0)
	var viewport_texture: ViewportTexture = background_material.albedo_texture
	viewport_texture.viewport_path = get_path_to(sim_viewport)
	background_material.albedo_texture = viewport_texture
	background.set_surface_override_material(0, background_material)

func _unhandled_input(event: InputEvent) -> void:
	if in_transition:
		return # Ignore input while transitioning

	# Move camera with mouse motion
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion_event := event as InputEventMouseMotion
		yaw -= motion_event.relative.x * mouse_sensitivity
		pitch -= motion_event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))
		head.rotation.y = yaw
		head.rotation.x = pitch

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
		# Move to next seat
		seat = (seat + 1) % (len(viewpoints))
		var viewpoint_node: Node3D = viewpoints[seat] as Node3D
		transform = viewpoint_node.transform
		# Reset view
		yaw = 0.0
		pitch = 0.0
		pitch = clamp(pitch, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))
		head.rotation.y = yaw
		head.rotation.x = pitch

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
