extends RigidBody3D

var ship
var torque = Vector3(0,0,0)
var max_torque = 0.5

func _ready():
	ship = get_parent()

func _process(_delta):
	torque = Vector3(0,0,0)
	
	if Input.is_action_pressed("down"):
		torque = torque + max_torque*(-transform.basis.z)
	if Input.is_action_pressed("up"):
		torque = torque + max_torque*(transform.basis.z)
		
	if Input.is_action_pressed("left"):
		torque = torque + max_torque*(transform.basis.y)
	if Input.is_action_pressed("right"):
		torque = torque + max_torque*(-transform.basis.y)
		
	if Input.is_action_pressed("roll_left"):
		torque = torque + max_torque*(-transform.basis.x)
	if Input.is_action_pressed("roll_right"):
		torque = torque + max_torque*(transform.basis.x)
		
	
	# Calculate autopilot response
	var target
	if ship.autopilot_flag:
		# Calculate target attitude
		match ship.current_mode:
			"HDG":
				# HDG is component of velocity normal to radius
				var v = Conversions.VelToFrame(OwnShip.velocity,SystemTime.t)
				var r = Conversions.FindFrame(SystemTime.t) - OwnShip.position
				var v_along_r = (r.dot(v)/r.length_squared())*r.normalized()
				target = v - v_along_r
			"CRS":
				target = Conversions.VelToFrame(OwnShip.velocity,SystemTime.t)
			"TRG":
				target = Conversions.FindFrame(SystemTime.t) - OwnShip.position
			"NRM":
				var v = Conversions.VelToFrame(OwnShip.velocity,SystemTime.t)
				var r = Conversions.FindFrame(SystemTime.t) - OwnShip.position
				target = r.cross(v)
			"NAV":
				target = ship.planned_acceleration
		
		# Calculate torque
		if target != null:
			# Normalize
			target = target.normalized()
			# Invert if invert key is depressed
			if ship.inv_flag:
				target = -target
			# Cross product for torque
			torque = torque + -target.cross(ship.attitude.x)
			
	# Calculate damping if stabilizers OR autopilot is enabled
	if ship.stab_flag or ship.autopilot_flag:
		torque -= 2*angular_velocity
	else:
		torque -= 0.1*angular_velocity
		
	# Apply torque
	apply_torque(torque)
		
	# Allow rotation if timestep is 1
	if SystemTime.step == 1:
		lock_rotation = false
	# Just point at target otherwise
	else:
		lock_rotation = true
		
		if target != null:
			look_at(target)
			rotate_object_local(Vector3(0, 1, 0), PI/2)
		
