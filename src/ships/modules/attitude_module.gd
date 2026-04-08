class_name AttitudeModule
extends Node3D

@onready var ship: PlayerShip = get_parent()
var torque := Vector3(0,0,0)
var max_torque := 5.0
var angular_velocity := Vector3(0,0,0)
var commanded_torque := Vector3(0,0,0)

var target_transform: Basis # transform that takes its target from autopilot

# Moment of inertia tensor (assuming diagonal for simplicity)
var inertia: Vector3 = Vector3(1, 1, 1)  # Modify based on spacecraft geometry
var inv_inertia: Vector3 = Vector3(1.0 / inertia.x, 1.0 / inertia.y, 1.0 / inertia.z)


func update(dt: float) -> void:
	# Calculate torque by increasing as you hold the button
	# Commanded torque is in ship frame
	var torque_rate := 0.5
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
	torque = ship.attitude*commanded_torque
	
	# Calculate autopilot response
	var target: Vector3
	if ship.avionics["autopilot"]:
		# Calculate target attitude
		match ship.avionics["attitude_mode"]:
			"HDG":
				# HDG is component of velocity normal to radius
				var v: Vector3 = Conversions.velocity_inertial_to_body(ShipData.player_ship.system_velocity,SimTime.t)
				var r: Vector3 = Conversions.find_body(SimTime.t) - ShipData.player_ship.system_position
				var v_along_r: Vector3 = (r.dot(v)/r.length_squared())*r.normalized()
				target = v - v_along_r
			"CRS":
				target = Conversions.velocity_inertial_to_body(ShipData.player_ship.system_velocity,SimTime.t)
			"TRG":
				target = Conversions.find_body(SimTime.t - dt) - ShipData.player_ship.system_position
			"NRM":
				var v: Vector3 = Conversions.velocity_inertial_to_body(ShipData.player_ship.system_velocity,SimTime.t)
				var r: Vector3 = Conversions.find_body(SimTime.t) - ShipData.player_ship.system_position
				target = r.cross(v)
			"NAV":
				target = ship.navigation_module.control_pointing
		
		# Calculate torque from autopilot
		if target != null:
			# Normalize
			target = target.normalized()
			# Invert if invert key is depressed
			if ship.avionics["attitude_inv"]:
				target = -target
			# Cross product for torque
			var Kp := 200.0 # control proportional gain
			torque = torque + -Kp*target.cross(ship.attitude.x)
			
	# Calculate damping if stabilizers OR autopilot is enabled
	if ship.avionics["attitude_stab"] or ship.avionics["autopilot"]:
		torque -= 3*(angular_velocity)
	else:
		torque -= 0.1*(angular_velocity)
		
	# Apply torque if in real time
	if SimTime.step == 1:
		ship.apply_torque(torque)
		
	# Disallow rotation if timestep is not 1
	elif SimTime.step != 1:
		angular_velocity = Vector3(0,0,0)
		
		# Point at target attitude
		if target.length() > 0.0:
			target_transform = transform_at(target, Vector3.UP)
			target_transform = target_transform.rotated(Vector3(0, 1, 0), -PI/2)
		else:
			target_transform = ship.attitude
		
func transform_at(forward: Vector3, up: Vector3) -> Basis:
	var f: Vector3 = forward.normalized()
	var r: Vector3 = up.cross(f).normalized()
	var u: Vector3 = f.cross(r).normalized()

	return Basis(r, u, f)
