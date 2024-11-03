extends Camera3D

var zoom_distance := 30.0
var zoom_speed := 1.2
var zoom_min := 7.0
var zoom_max := 2000000.0

var rotation_speed := 0.0001
var r := false
var pitch := 0.0
var yaw := 0.0

var bodies = ["Sun","Mercury","Venus","Earth","Mars","Jupiter","Saturn","Uranus","Neptune"]
var i = 3

func _process(_delta):
	get_parent().get_parent().get_node("Grid").scale = 4*zoom_distance*Vector3(1,1,1)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_X:
			zoom_distance = zoom_speed*zoom_distance
		elif event.pressed and event.keycode == KEY_Z:
			zoom_distance = zoom_distance/zoom_speed

		zoom_distance = clamp(zoom_distance, zoom_min, zoom_max)
		position = Vector3(0, 0, zoom_distance)
		
		if event.pressed and event.keycode == KEY_TAB:
			i = (i + 1) % 9
			get_parent().get_parent().reparent(get_parent().get_parent().get_parent().get_parent().get_node(bodies[i]))
			get_parent().get_parent().position = Vector3(0,0,0)

	# Right-click rotate
	elif event is InputEventMouseButton and event.button_index == 2:
		if !r:
			r = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif r:
			r = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if r:
		yaw -= Input.get_last_mouse_velocity().x * rotation_speed
		pitch = clamp(pitch - Input.get_last_mouse_velocity().y * rotation_speed, -1.2, 1.2)
		
		# Set rotation on the parent, CameraRig
		get_parent().rotation = Vector3(pitch, yaw, 0)
