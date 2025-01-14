extends Camera3D

@export var zoomable : bool
@export var reparentable : bool

@export var zoom_distance := 30.0
var zoom_speed := 1.2
var zoom_min := 7.0
var zoom_max := 2000000.0

var rotation_speed := 0.0001
var r := false
var pitch := 0.0
var yaw := 0.0

var viewer

var bodies = ["Sun","Mercury","Venus","Earth","Mars","Jupiter","Saturn","Uranus","Neptune"]
var i = 3

func _ready():
	viewer = get_viewport().get_parent()

func _process(_delta):
	if viewer.is_visible_in_tree():
		if zoomable:
			if Input.is_action_pressed("zoom_out") or Input.is_action_just_released("zoom_out"):
				zoom_distance = zoom_speed*zoom_distance
			if Input.is_action_pressed("zoom_in") or Input.is_action_just_released("zoom_in"):
				zoom_distance = zoom_distance/zoom_speed
			zoom_distance = clamp(zoom_distance, zoom_min, zoom_max)
			position = Vector3(0, 0, zoom_distance)
		
		if reparentable:
			if Input.is_action_pressed("switch_planet"):
					i = (i + 1) % 9
					get_parent().get_parent().reparent(get_parent().get_parent().get_parent().get_parent().get_node(bodies[i]))
					get_parent().get_parent().position = Vector3(0,0,0)
		
		# Handle arrow keys rotation	
		if Input.is_action_pressed("mod_up"):
			pitch = pitch - 100*rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_down"):
			pitch = pitch + 100*rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_left"):
			yaw = yaw - 100*rotation_speed
			set_orientation()
		if Input.is_action_pressed("mod_right"):
			yaw = yaw + 100*rotation_speed
			set_orientation()
	


func _unhandled_input(event):
	# Right-click rotate
	if event is InputEventMouseButton and event.button_index == 2:
		if !r:
			r = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif r:
			r = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if r:
		set_orientation()
		
func set_orientation():
	yaw -= Input.get_last_mouse_velocity().x * rotation_speed
	pitch = clamp(pitch - Input.get_last_mouse_velocity().y * rotation_speed, -1.57, 1.57)
	
	# Set rotation on the parent, CameraRig
	get_parent().rotation = Vector3(pitch, yaw, 0)
