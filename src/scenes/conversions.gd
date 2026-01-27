extends Node

# Path to the body that the frame is defined by
var frame_name: String = "SolarSystem/Earth"


# ------------------------------------------------------------
# Utility
# ------------------------------------------------------------

func _get_frame_body() -> Node:
	return ShipData.sim_root.get_node(frame_name)


# ------------------------------------------------------------
# Frame Conversions
# Inertial - solar system frame
# Body - body centered frame
# ------------------------------------------------------------

func inertial_to_ship_frame(
	positions: Array[Vector3],
	times: Array[float]
) -> Array[Vector3]:

	# Place the interial frame positions into relative to ship positions
	# Used to placer propagated positions in trajectory
	# Each point is now how much the craft has moved since t0
	# minus how much the frame has moved since t0

	var new_positions: Array[Vector3] = []
	new_positions.resize(positions.size())

	var body_node: Node = _get_frame_body()

	var body_at_t0: Vector3 = body_node.call("fetch", times[0])

	for i in positions.size():
		new_positions[i] = (
			positions[i]
			- positions[0]
			- body_node.call("fetch", times[i])
			+ body_at_t0
		)

	return new_positions

func position_body_to_inertial(position: Vector3, t: float) -> Vector3:
	# Convert body-relative position → inertial
	var body_node: Node = _get_frame_body()
	return position + body_node.call("fetch", t)

func position_inertial_to_body(position: Vector3, t: float) -> Vector3:
	# Convert inertial → body-relative
	var body_node: Node = _get_frame_body()
	return position - body_node.call("fetch", t)

func velocity_body_to_inertial(v: Vector3, t: float) -> Vector3:
	# Convert frame-relative velocity → universal velocity
	var body_node: Node = _get_frame_body()

	var vel: Vector3 = (
		body_node.call("fetch", t + 1.0)
		- body_node.call("fetch", t)
	)

	return v + vel

func velocity_inertial_to_body(v: Vector3, t: float) -> Vector3:
	# Convert universal velocity → frame-relative velocity
	var body_node: Node = _get_frame_body()

	var vel: Vector3 = (
		body_node.call("fetch", t + 1.0)
		- body_node.call("fetch", t)
	)

	return v - vel

func find_body(t: float) -> Vector3:
	# Returns position of current frame origin in inertial coordinates
	var body_node: Node = _get_frame_body()
	return body_node.call("fetch", t)


# ------------------------------------------------------------
# Orbital Mechanics
# ------------------------------------------------------------

func calc_eccentricity(r: Vector3, v: Vector3, t: float) -> Vector3:
	# Calculates eccentricity vector

	var body_node: Node = _get_frame_body()
	var mu: float = body_node.get("GM")

	var r_frame: Vector3 = position_inertial_to_body(r, t)
	var v_frame: Vector3 = velocity_inertial_to_body(v, t)

	var h_frame: Vector3 = r_frame.cross(v_frame)

	var e: Vector3 = (1.0 / mu) * (
		v_frame.cross(h_frame)
		- mu * r_frame / r_frame.length()
	)

	return e


func calc_excess(r: Vector3, v: Vector3, t: float) -> float:
	# Hyperbolic excess velocity

	var body_node: Node = _get_frame_body()
	var mu: float = body_node.get("GM")

	var r_frame: Vector3 = position_inertial_to_body(r, t)
	var v_frame: Vector3 = velocity_inertial_to_body(v, t)

	var v_esc: float = sqrt(2.0 * mu / r_frame.length())
	var v_exc: float = v_frame.length() - v_esc

	return v_exc

# ------------------------------------------------------------
# Formatting for outputs
# ------------------------------------------------------------

# Formatting times
func format_time(seconds: float) -> String:
	var signs := "T+"
	if seconds < 0:
		signs = "T-"
		seconds = abs(seconds)

	# Break down
	var leftover_seconds: int = roundi(seconds)
	
	# Format into days
	@warning_ignore("integer_division")
	var days := int(leftover_seconds / 86400)
	leftover_seconds = leftover_seconds % 86400
	
	# Format into hours
	@warning_ignore("integer_division")
	var hours := int(leftover_seconds / 3600)
	leftover_seconds = leftover_seconds % 3600
	
	# Format into minutes
	@warning_ignore("integer_division")
	var minutes := int(leftover_seconds / 60)
	leftover_seconds = leftover_seconds % 60
	
	# Format into seconds
	var secs := int(leftover_seconds)

	# Cap days at 99
	if days > 99:
		return "%s99d23h59m59s" % signs

	return "%s%02dd%02dh%02dm%02ds" % [signs, days, hours, minutes, secs]
