class_name AttitudeModule
extends Node3D

@onready var ship: PlayerShip = get_parent()

var max_torque       := 50.0
var max_slew_rate    := 0.1   # rad/s, commanded limit (user-facing parameter)

var target_attitude: Quaternion  # set externally by autopilot modes
var commanded_torque := Vector3.ZERO
var torque           := Vector3.ZERO

func update(dt: float) -> void:
	max_slew_rate = 0.1
	# Get input body frame torque depending on mode
	var manual_torque := Vector3.ZERO
	var ap_torque := Vector3.ZERO
	if ship.avionics["attitude_stab"]:
		var rate_command := max_slew_rate*_read_manual_input()
		ap_torque = _rate_controller(rate_command)
	else:
		manual_torque = max_torque*_read_manual_input()

	if ship.avionics["autopilot"]:
		var tgt_dir := _resolve_target_direction(dt)
		if tgt_dir != Vector3.ZERO:
			target_attitude = _attitude_from_forward(tgt_dir)
		ap_torque = _rate_controller(_slew_rate_command())

	# Combine, clamp, and put in global frame
	torque = manual_torque + ap_torque
	torque = ship.transform.basis * torque.limit_length(max_torque)

	if SimTime.step == 1:
		ship.apply_torque(torque)
	else:
		# Set torque to zero so thrusters aren't seen firing
		torque = Vector3.ZERO

func _rate_controller(omega_commanded: Vector3) -> Vector3:
	var omega_body := ship.attitude.inverse() * ship.angular_velocity
	var omega_err  := omega_commanded - omega_body

	# Kp here is just alpha_max — apply full torque per unit rate error,
	# saturate to bang-bang
	var Kp := 10.0*Vector3.ONE
	var u := Kp*Vector3(
		clampf(omega_err.x, -1.0, 1.0),
		clampf(omega_err.y, -1.0, 1.0),
		clampf(omega_err.z, -1.0, 1.0)
	)
	# Returns body frame torque
	return u * max_torque

func _slew_rate_command() -> Vector3:
	var q_current := Quaternion(ship.attitude)
	var q_err     := q_current.inverse() * target_attitude
	if q_err.w < 0.0:
		q_err = -q_err

	var theta_err := 2.0 * Vector3(q_err.x, q_err.y, q_err.z)
	var Kp := 1.0*Vector3.ONE
	var omega_cmd := Kp * theta_err
	return Vector3(
		clampf(omega_cmd.x, -max_slew_rate, max_slew_rate),
		clampf(omega_cmd.y, -max_slew_rate, max_slew_rate),
		clampf(omega_cmd.z, -max_slew_rate, max_slew_rate)
	)

func _resolve_target_direction(dt: float) -> Vector3:
	var target := Vector3.ZERO
	match ship.avionics["attitude_mode"]:
		"HDG":
			var v := Conversions.velocity_inertial_to_body(ShipData.player_ship.system_velocity, SimTime.t)
			var r := Conversions.find_body(SimTime.t) - ShipData.player_ship.system_position
			target = v - (r.dot(v) / r.length_squared()) * r
		"CRS":
			target = Conversions.velocity_inertial_to_body(ShipData.player_ship.system_velocity, SimTime.t)
		"TRG":
			target = Conversions.find_body(SimTime.t - dt) - ShipData.player_ship.system_position
		"NRM":
			var v := Conversions.velocity_inertial_to_body(ShipData.player_ship.system_velocity, SimTime.t)
			var r := Conversions.find_body(SimTime.t) - ShipData.player_ship.system_position
			target = r.cross(v)
		"NAV":
			target = ship.navigation_module.control_pointing

	if target.length_squared() < 1e-6:
		return Vector3.ZERO
	target = target.normalized()
	if ship.avionics["attitude_inv"]:
		target = -target
	return target

# Build a target quaternion from a desired forward direction.
# Preserves roll by keeping current up as close as possible.
func _attitude_from_forward(forward: Vector3) -> Quaternion:
	var x := forward.normalized()
	
	# Use a FIXED world-frame up reference, not the ship's current up.
	# This fully constrains roll rather than letting it drift.
	var up_hint := Vector3(0,0,1)  # world Y
	
	#if abs(x.dot(up_hint)) > 0.99:  # forward is nearly parallel to up
#		up_hint = Vector3(0.0, 0.0, 1.0)  # fall back to world Z
	
	var z := x.cross(up_hint).normalized()   # ship +Z = forward cross up
	var y := z.cross(x).normalized()         # ship +Y = reorthogonalized up
	return Quaternion(Basis(x, y, z))        # Basis(+X, +Y, +Z) in ship frame


func _read_manual_input() -> Vector3:
	var cmd := Vector3.ZERO
	var pitch := Input.get_axis("down", "up")
	var yaw := Input.get_axis("right", "left")
	var roll := Input.get_axis("roll_left", "roll_right")
	cmd.z = pitch
	cmd.y = yaw
	cmd.x = roll
	# Rotate manual command (body frame) to world frame
	return cmd.clampf(-1.0, 1.0)
