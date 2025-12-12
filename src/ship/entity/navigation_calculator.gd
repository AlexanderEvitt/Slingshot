extends Node3D

var control = Vector3(0,0,0) # commanded acceleration
var control_pointing = Vector3(1,0,0) # normalized direction of control
var control_throttle = 0 # scalar acceleration of control

var active_waypoint = 0
var waypoints = []

# Scalar projection factor t (scalar form of projection position onto from, 0 -> 1)
var t = 0.0

var cornering_velocity = 0.0 # target velocity at endpoint, km/s

@export var Kp = 0.00001 # 5,000km max deflection
@export var Ki = 0.000000001 # Kp/10000
@export var Kd = 0.05 # 1km/s max deflection

# Persistent navigation data
var course = Vector3(0,0,0)
var course_distance = 0.0
var normalized_course = Vector3(0,0,0)
var closest_point = Vector3(0,0,0)
var relative_velocity = Vector3(0,0,0)
var on_course_velocity = Vector3(0,0,0)
var from = Vector3(0,0,0)
var to = Vector3(0,0,0)
var from_vel = Vector3(0,0,0)
var to_vel = Vector3(0,0,0)
var remaining_distance = 0.0
var p_error = Vector3(0,0,0)
var i_error = Vector3(0,0,0) # integral error needs to persist between frames
var d_error = Vector3(0,0,0)
var a2 = Vector3(0,0,0)
var a3 = Vector3(0,0,0)
var scalek = 1.0


@onready var ship = get_parent()

var reverse = false

# Run by ship calculator, accelerates with time warp
func update(dt, gravity):
	# Update waypoints, only navigate if you have two of them or more
	waypoints = ship.waypoints
	if waypoints.size() > 1 and SystemTime.step > 0 and ship.avionics["navigation"] and ship.avionics["autopilot"]:
		# Don't navigate if there's no waypoints or the simulation isn't advancing
		navigate(dt, gravity)

	else:
		control = Vector3(0,0,0)
		
# Run by ship calculator, only every physics frame
func update_periodically():
	# Update waypoints, only navigate if you have two of them or more
	waypoints = ship.waypoints
	if waypoints.size() > 1 and SystemTime.step > 0 and ship.avionics["navigation"] and ship.avionics["autopilot"]:
		# Update waypoints, course info
		var last_waypoint = waypoints[active_waypoint]
		var next_waypoint = waypoints[active_waypoint + 1]
		
		# Write the current solar system positions/velocities of the waypoints
		from = last_waypoint["Position"] + last_waypoint["Frame"].fetch(SystemTime.t)
		to = next_waypoint["Position"] + next_waypoint["Frame"].fetch(SystemTime.t)
		from_vel = last_waypoint["Frame"].fetch_velocity(SystemTime.t)
		to_vel = next_waypoint["Frame"].fetch_velocity(SystemTime.t)

		# Get the course (vector from previous point to next point)
		course = (to - from)
		course_distance = course.length()
		normalized_course = course.normalized()
	
func navigate(dt, gravity):
	# Get the nearest point along the line
	# Scalar projection factor t (scalar form of projection position onto from, 0 -> 1)
	t = (ship.position - from).dot(course) / (course_distance * course_distance)
	# Closest point on the infinite line
	closest_point = from + t * course
	
	# Get the velocity relative to the line (linear combination of endpoint velocity)
	relative_velocity = ship.velocity - (t*to_vel + (1.0 - t)*from_vel)
	# Component of that in the direction of course
	on_course_velocity = relative_velocity.project(course)

	# Calculate acceleration [a1] in opposition to gravity
	var a1 = -gravity
	
	# Calculate error correction [a2] to move towards course
	# Vector from ship to closest point (orthogonal to line direction)
	p_error = closest_point - ship.position
	# Integral error (integrated position error)
	i_error = i_error + p_error*dt
	# Velocity error (velocity not in the direction of course)
	d_error = on_course_velocity - relative_velocity
	# Sum up, reducing gains with time rate to reduce jitter
	if SystemTime.step > 100:
		scalek = 1.0/(log(SystemTime.step/100) + 1)
	else:
		scalek = 1.0
	a2 = (Kp*scalek)*p_error + (Ki*scalek)*i_error + (Kd*scalek)*d_error
	
	# Calculate thrust along line [a3]
	# Calculate required thrust to hit cornering_velocity at endpoint
	remaining_distance = course_distance * (1.0 - t)
	var required_decel = abs((cornering_velocity**2 - on_course_velocity.length_squared())/(2*remaining_distance))
	if reverse: # deceleration thrust
		a3 = -required_decel*normalized_course
	else: # acceleration thrust
		a3 = 0.01*normalized_course
	# Enable flip if the required deceleration goes over
	if required_decel > 0.01:
		reverse = true
	
	# Sum thrust and clamp
	control = a1 + a2 + a3
	control = control.limit_length(0.05)
	
	# Move to next waypoint if near it, disable NAV if at destination
	var direction = relative_velocity.normalized().dot(normalized_course) # 1 to -1, alignment of velocity with course
	if t > 1 or (t > 0.9 and direction < 0):
		if active_waypoint + 2 >= len(waypoints):
			# Shut off navigation
			ship.nav_disc.emit()
			ship.auto_disc.emit()
			ship.avionics["navigation"] = false
			ship.avionics["autopilot"] = false
			control = Vector3(0,0,0)
			reverse = false
			i_error = Vector3(0,0,0)
		else:
			# Move to next waypoint
			active_waypoint = active_waypoint + 1
			ship.nav_next.emit()
			reverse = false
			i_error = Vector3(0,0,0)
	
	# Split control into pointing and throttle command
	control_throttle = control.length()
	if control_throttle > 0:
		control_pointing = control.normalized()
	else:
		# Point retrocourse at autopilot shutoff
		control_pointing = -normalized_course
	# Don't fire engine if pointing is incorrect
	var attitude_error = acos(control_pointing.dot(ship.attitude.x)) # radians
	if attitude_error > 0.087: # 5 degree tolerance
		control_throttle = 0
