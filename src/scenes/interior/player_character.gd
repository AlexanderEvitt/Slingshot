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
@onready var raycast: RayCast3D = $Head/RayCast3D
@onready var crosshair: Control = $Head/Camera3D/Crosshair
@onready var pause_menu: Control = $Head/Camera3D/PauseMenu
@onready var background: MeshInstance3D = $Head/Camera3D/Background

# Get the viewport that sees the simulation (should be a sibling)
@onready var sim_viewport: SubViewport = get_parent().get_node("SimViewport")

# Get the list of nodes that the player can snap to
# This is assigned by the interior model loader
@onready var viewpoints: Array[Node]
var seat := -1 # which viewpoint you're attached to

var yaw := 0.0
var pitch := 0.0

var in_transition := false
var seated := false
var focusing := false
var transition_t := 0.0

# Holders for the transforms that define looking at screens
var start_view: Node3D
var end_view: Node3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Assign viewport texture to background
	var background_material: StandardMaterial3D = background.get_active_material(0)
	var viewport_texture: ViewportTexture = background_material.albedo_texture
	viewport_texture.viewport_path = get_path_to(sim_viewport)
	background_material.albedo_texture = viewport_texture
	background.set_surface_override_material(0, background_material)
	
	# Start at 0th seat, must be deferred because viewpoints don't exist until
	# parent of interior scene adds interior model
	call_deferred("go_to_next_seat")

func _unhandled_input(event: InputEvent) -> void:
	if in_transition:
		return # Ignore input while transitioning

	# Move camera with mouse motion
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and !focusing and !in_transition:
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
		go_to_next_seat()
		
	if Input.is_action_pressed("arrow_up"):
		position = position - 0.1*head.transform.basis.z

# Move to next seat
func go_to_next_seat() -> void:
	# Move to next seat
	seat = (seat + 1) % (len(viewpoints))
	var viewpoint_node: Node3D = viewpoints[seat] as Node3D
	transform = viewpoint_node.transform
	reset_view()
	
func reset_view() -> void:
	# Reset view to look straight ahead
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
			var collider_parent: Node3D = collider.get_parent() # nominally the display
			if collider and collider_parent.has_node("Viewpoint"):
				# Start where the head is
				start_view = head
				# Go to where the display's viewpoint is
				end_view = collider_parent.get_node("Viewpoint")
				focusing = true
				in_transition = true
				transition_t = 0.0
				# Mouse visible, cross hair not
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				crosshair.visible = false
	else:
		# Return to original position
		start_view = end_view # start at display viewpoint
		end_view = head # reset to camera's default local zero
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

		camera.global_transform = start_view.global_transform.interpolate_with(end_view.global_transform, t)

		if t >= 1.0:
			in_transition = false
