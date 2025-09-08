extends Node3D

var control = Vector3(0,0,0)
var active_waypoint = 0
var waypoints = []

var proportional_error = Vector3(0,0,0)
var last_proportional_error = Vector3(0,0,0)

var cornering_velocity = 0.0 # target velocity at endpoint, km/s

@export var Kp = 0.000005 # 10,000km max deflection
@export var Kd = 0.05 # 1km/s max deflection

@onready var ship = get_parent()
@onready var game_root = get_tree().root.get_node("GameRoot/")

func _process(_delta):
	# Update waypoints, only navigate if you have two of them or more
	waypoints = ship.waypoints
	if waypoints.size() > 1 and SystemTime.step > 0:
		# Don't navigate if there's no waypoints or the simulation isn't advancing
		navigate()

	else:
		control = Vector3(0,0,0)
	
func navigate():
	# Update waypoints, course info
	var last_waypoint = waypoints[active_waypoint]
	var next_waypoint = waypoints[active_waypoint + 1]
	# Write the current solar system positions/velocities of the waypoints
	var from = last_waypoint["Position"] + game_root.get_node(last_waypoint["Frame"]).fetch(SystemTime.t)
	var to = next_waypoint["Position"] + game_root.get_node(next_waypoint["Frame"]).fetch(SystemTime.t)
	var from_vel = game_root.get_node(last_waypoint["Frame"]).fetch_velocity(SystemTime.t)
	var to_vel = game_root.get_node(next_waypoint["Frame"]).fetch_velocity(SystemTime.t)

	# Get the course (vector from previous point to next point)
	var course = (to - from)
	
	# Get the nearest point along the line
	# Parametric projection factor t (scalar form of projection position onto from, 0 to 1)
	var t = (ship.position - from).dot(course) / course.length_squared()
	print("t: ", t)
	# Closest point on the infinite line
	var closest_point = from + t * course
	
	# Get the velocity relative to the line (linear combination of endpoint velocity)
	var relative_velocity = ship.velocity - (t*to_vel + (1.0 - t)*from_vel)
	# Component of that in the direction of course
	var on_course_velocity = relative_velocity.project(course)

	# Calculate acceleration [a1] in opposition to gravity
	var a1 = -ship.propagator.Acceleration(ship.position,SystemTime.t)
	
	# Calculate error correction [a2] to move towards course
	# Vector from ship to closest point (orthogonal to line direction)
	var position_error = closest_point - ship.position
	# Velocity error (velocity not in the direction of course)
	var velocity_error = on_course_velocity - relative_velocity
	# Sum up, reducing gains with time rate to reduce jitter
	var scalek = 1.0/(log(SystemTime.step) + 1)
	var a2 = (Kp*scalek)*position_error + (Kd*scalek)*velocity_error
	
	print("PE: ", position_error)
	print("VE: ", velocity_error)
	print("Proportional term: ", (Kp*scalek)*position_error.length())
	print("Derivative term: ", (Kd*scalek)*velocity_error.length())
	
	# Calculate thrust along line [a3]
	# Calculate required thrust to hit cornering_velocity at endpoint
	var remaining_distance = course.length() * (1.0 - t)
	var required_decel = abs((cornering_velocity**2 - on_course_velocity.length_squared())/(2*remaining_distance))
	var a3
	if required_decel < 0.01:
		a3 = 0.01*course.normalized()
	else:
		a3 = -required_decel*course.normalized()
	
	# Sum thrust and clamp
	control = a1 + a2 + a3
	control = control.limit_length(0.05)
	
	# Move to next waypoint if near it, disable NAV if at destination
