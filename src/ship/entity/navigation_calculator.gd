extends Node3D

var control = Vector3(0,0,0) # commanded acceleration
var control_pointing = Vector3(1,0,0) # normalized direction of control
var control_throttle = 0 # scalar acceleration of control

var active_waypoint = 0
var waypoints = []

var i_error = Vector3(0,0,0) # integral error needs to persist between frames

var cornering_velocity = 0.0 # target velocity at endpoint, km/s

@export var Kp = 0.00001 # 5,000km max deflection
@export var Ki = 0.000000001 # Kp/10000
@export var Kd = 0.05 # 1km/s max deflection

@onready var ship = get_parent()
@onready var game_root = get_tree().root.get_node("GameRoot/")

var report = true
var count = 0 # counter for when to write report

var reverse = false

# Run by ship calculator
func update(dt, gravity):
	# Update waypoints, only navigate if you have two of them or more
	waypoints = ship.waypoints
	if waypoints.size() > 1 and SystemTime.step > 0 and ship.nav_flag and ship.autopilot_flag:
		# Don't navigate if there's no waypoints or the simulation isn't advancing
		navigate(dt, gravity)

	else:
		control = Vector3(0,0,0)
		
	if report:
		count = (count + 1) % 3000
	
func navigate(dt, gravity):
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
	# Scalar projection factor t (scalar form of projection position onto from, 0 -> 1)
	var t = (ship.position - from).dot(course) / course.length_squared()
	# Closest point on the infinite line
	var closest_point = from + t * course
	
	# Get the velocity relative to the line (linear combination of endpoint velocity)
	var relative_velocity = ship.velocity - (t*to_vel + (1.0 - t)*from_vel)
	# Component of that in the direction of course
	var on_course_velocity = relative_velocity.project(course)

	# Calculate acceleration [a1] in opposition to gravity
	var a1 = -gravity
	
	# Calculate error correction [a2] to move towards course
	# Vector from ship to closest point (orthogonal to line direction)
	var p_error = closest_point - ship.position
	# Integral error (integrated position error)
	i_error = i_error + p_error*dt
	# Velocity error (velocity not in the direction of course)
	var d_error = on_course_velocity - relative_velocity
	# Sum up, reducing gains with time rate to reduce jitter
	var scalek = 1.0
	if SystemTime.step > 100:
		scalek = 1.0/(log(SystemTime.step/100) + 1)
	var a2 = (Kp*scalek)*p_error + (Ki*scalek)*i_error + (Kd*scalek)*d_error
	
	# Calculate thrust along line [a3]
	# Calculate required thrust to hit cornering_velocity at endpoint
	var remaining_distance = course.length() * (1.0 - t)
	var required_decel = abs((cornering_velocity**2 - on_course_velocity.length_squared())/(2*remaining_distance))
	var a3
	if reverse: # deceleration thrust
		a3 = -required_decel*course.normalized()
	else: # acceleration thrust
		a3 = 0.01*course.normalized()
	# Enable flip if the required deceleration goes over
	if required_decel > 0.01:
		reverse = true
	
	# Sum thrust and clamp
	control = a1 + a2 + a3
	control = control.limit_length(0.05)
	
	# Move to next waypoint if near it, disable NAV if at destination
	var direction = relative_velocity.normalized().dot(course.normalized()) # 1 to -1, alignment of velocity with course
	if t > 1 or (t > 0.9 and direction < 0):
		if active_waypoint + 2 >= len(waypoints):
			# Shut off navigation
			ship.nav_disc.emit()
		else:
			# Move to next waypoint
			active_waypoint = active_waypoint + 1
			ship.nav_next.emit()
			reverse = false
	
	# Split control into pointing and throttle command
	control_pointing = control.normalized()
	control_throttle = control.length()
	# Don't fire engine if pointing is incorrect
	var attitude_error = acos(control_pointing.dot(ship.attitude.x)) # radians
	if attitude_error > 0.087: # 5 degree tolerance
		control_throttle = 0
	
	# Write report for debugging
	if count == 0:
		print("Navigating to: ", active_waypoint)
		print("	Flying reverse: ", reverse)
		print("	t: ", t)
		print("	Errors - P: ", p_error.length(), " | I: ", i_error.length(), " | D: ", d_error.length())
		print("	Throttles - P: ", (Kp*scalek)*p_error.length()/0.05, " | I: ", (Ki*scalek)*i_error.length()/0.05, " | D: ", (Kd*scalek)*d_error.length()/0.05)
	
