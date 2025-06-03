extends Node3D

var ship
var torque = Vector3(0,0,0)
var max_torque = 0.4
var angular_velocity = Vector3(0,0,0)
var commanded_torque = Vector3(0,0,0)

# Moment of inertia tensor (assuming diagonal for simplicity)
var inertia: Vector3 = Vector3(1, 1, 1)  # Modify based on spacecraft geometry
var inv_inertia: Vector3 = Vector3(1.0 / inertia.x, 1.0 / inertia.y, 1.0 / inertia.z)

func _ready():
	ship = get_parent()

func _process(_delta):
	# Calculate torque by increasing as you hold the button
	# Commanded torque is in ship frame
	var torque_rate = 0.02
	# Add torque if button is held down, set to zero if not
	if Input.is_action_pressed("down"):
		commanded_torque.z += -torque_rate
	elif Input.is_action_pressed("up"):
		commanded_torque.z += torque_rate
	else:
		commanded_torque.z = 0
		
	if Input.is_action_pressed("left"):
		commanded_torque.y += torque_rate
	elif Input.is_action_pressed("right"):
		commanded_torque.y += -torque_rate
	else:
		commanded_torque.y = 0
		
	if Input.is_action_pressed("roll_left"):
		commanded_torque.x += -torque_rate
	elif Input.is_action_pressed("roll_right"):
		commanded_torque.x += torque_rate
	else:
		commanded_torque.x = 0
		
	# Clamp to max allowable torque
	commanded_torque = commanded_torque.clampf(-max_torque, max_torque)
	# Convert to global frame
	torque = transform.basis*commanded_torque
	
	# Calculate autopilot response
	var target
	if ship.autopilot_flag:
		# Calculate target attitude
		match ship.current_mode:
			"HDG":
				# HDG is component of velocity normal to radius
				var v = Conversions.VelToFrame(ShipData.player_ship.velocity,SystemTime.t)
				var r = Conversions.FindFrame(SystemTime.t) - ShipData.player_ship.position
				var v_along_r = (r.dot(v)/r.length_squared())*r.normalized()
				target = v - v_along_r
			"CRS":
				target = Conversions.VelToFrame(ShipData.player_ship.velocity,SystemTime.t)
			"TRG":
				target = Conversions.FindFrame(SystemTime.t) - ShipData.player_ship.position
			"NRM":
				var v = Conversions.VelToFrame(ShipData.player_ship.velocity,SystemTime.t)
				var r = Conversions.FindFrame(SystemTime.t) - ShipData.player_ship.position
				target = r.cross(v)
			"NAV":
				target = ship.planned_acceleration
		
		# Calculate torque from autopilot
		if target != null:
			# Normalize
			target = target.normalized()
			# Invert if invert key is depressed
			if ship.inv_flag:
				target = -target
			# Cross product for torque
			var Kp = 2.0 # control proportional gain
			torque = torque + -Kp*target.cross(ship.attitude.x)
			
	# Calculate damping if stabilizers OR autopilot is enabled
	if ship.stab_flag or ship.autopilot_flag:
		torque -= 3*(angular_velocity)
	else:
		torque -= 0.1*(angular_velocity)
		
	# Apply torque if in real time
	if SystemTime.step == 1:
		integrate_rotation(torque)
		
	# Disallow rotation if timestep is not 1
	elif SystemTime.step != 1:
		angular_velocity = Vector3(0,0,0)
		
		# Point at target attitude
		if target != null:
			transform.basis = transform_at(target, Vector3.UP)
			rotate_object_local(Vector3(0, 1, 0), -PI/2)
			

func integrate_rotation(applied_torque):
	# Compute angular acceleration using Euler's equations
	#applied_torque = transform.basis.inverse()*applied_torque
	var dt = 0.03333
	var inertia_cross_omega = Vector3(
		(inertia.y - inertia.z) * angular_velocity.y * angular_velocity.z,
		(inertia.z - inertia.x) * angular_velocity.z * angular_velocity.x,
		(inertia.x - inertia.y) * angular_velocity.x * angular_velocity.y)

	var angular_acceleration = (applied_torque - inertia_cross_omega) * inv_inertia

	# Integrate angular velocity using explicit Euler method
	angular_velocity += angular_acceleration * dt

	# Convert local angular velocity to a rotation quaternion
	# Apply rotation using Godot's built-in method
	var ang_speed = angular_velocity.length()
	if ang_speed > 0.0:
		var rotation_axis = angular_velocity.normalized()
		var ang_vel_quat = Quaternion(rotation_axis, ang_speed * dt)  # Axis-angle representation
		transform.basis = Basis(ang_vel_quat) * transform.basis
		transform = transform.orthonormalized()
		
func transform_at(forward: Vector3, up: Vector3) -> Basis:
	var f = forward.normalized()
	var r = up.cross(f).normalized()
	var u = f.cross(r).normalized()

	return Basis(r, u, f)
