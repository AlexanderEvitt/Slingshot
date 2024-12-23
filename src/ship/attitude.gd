extends RigidBody3D

func _process(_delta):
	# Change time scale to system time step
	# accelerate rotational dynamics with time scaling
	#Engine.time_scale = SystemTime.step
	
	if Input.is_action_pressed("down"):
		apply_torque(-transform.basis.z)
	if Input.is_action_pressed("up"):
		apply_torque(transform.basis.z)
		
	if Input.is_action_pressed("left"):
		apply_torque(transform.basis.y)
	if Input.is_action_pressed("right"):
		apply_torque(-transform.basis.y)
		
	if Input.is_action_pressed("roll_left"):
		apply_torque(-transform.basis.x)
	if Input.is_action_pressed("roll_right"):
		apply_torque(transform.basis.x)
