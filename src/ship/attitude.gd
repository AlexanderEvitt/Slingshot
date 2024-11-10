extends RigidBody3D

func _process(_delta):
	if Input.is_action_pressed("down"):
		apply_torque(Vector3(0,0,-1))
	if Input.is_action_pressed("up"):
		apply_torque(Vector3(0,0,1))
		
	if Input.is_action_pressed("left"):
		apply_torque(Vector3(0,1,0))
	if Input.is_action_pressed("right"):
		apply_torque(Vector3(0,-1,0))
		
	if Input.is_action_pressed("roll_left"):
		apply_torque(Vector3(1,0,0))
	if Input.is_action_pressed("roll_right"):
		apply_torque(Vector3(-1,0,0))
