extends Node3D

var control = Vector3(0,0,0)
var active_waypoint = 0
var waypoints = []

var proportional_error = Vector3(0,0,0)
var last_proportional_error = Vector3(0,0,0)

@export var Kp = 0.0025
@export var Kd = 0.25

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
	# Write the current solar system positions of the waypoints
	var from = last_waypoint["Position"] + game_root.get_node(last_waypoint["Frame"]).fetch(SystemTime.t)
	var to = next_waypoint["Position"] + game_root.get_node(next_waypoint["Frame"]).fetch(SystemTime.t)
	# Write the course
	var course = (to - from).normalized()

	
	# Calculate acceleration [a1] in opposition to gravity
	var a1 = -ship.propagator.Acceleration(ship.position,SystemTime.t)
	
	# Calculate error correction [a2] to move towards course
	# Parametric projection factor t
	var t = (ship.position - from).dot(course) / course.length_squared()
	# Closest point on the infinite line
	var closest_point = from + t * course
	# Vector from ship to that point (orthogonal to line direction)
	last_proportional_error = proportional_error
	proportional_error = closest_point - ship.position
	# Velocity error from direction
	var velocity_error = (proportional_error - last_proportional_error)/(SystemTime.step*0.0333)
	# Sum up, reducing gains with time rate to reduce jitter
	var a2 = (Kp/SystemTime.step)*proportional_error + (Kd/SystemTime.step)*velocity_error
	
	print("PE: ", proportional_error)
	print("VE: ", velocity_error)
	
	# Calculate thrust along line [a3]
	var a3 = 0.01*course
	
	# Sum thrust and clamp
	control = a1 + a2 + a3
	control = control.limit_length(0.05)
	
	# Move to next waypoint if near it, disable NAV if at destination
