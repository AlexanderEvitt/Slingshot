extends Node

var position
var velocity
var attitude

var torque

var propagator
var plotted_positions

var thrust = 0

@export var start_position : Vector3
@export var start_velocity : Vector3

var attitude_calculator

# Autopilot modes
var current_mode
var inv_flag
var stab_flag
var autopilot_flag
var nav_flag

# Planned stuff
var planned_positions
var planned_velocities
var planned_acceleration

# Signals
signal auto_disc
signal nav_disc

var previous_dt = 0.03333
var previous_t = 0


# this module moves data from the master scene an autoload where others can access it

func _ready():
	attitude_calculator = get_node("AttitudeCalculator")
	propagator = get_node("Propagator")
	
	# Initialize values
	attitude = attitude_calculator.transform.basis
	position = Conversions.ToUniversal(start_position,0)
	velocity = Conversions.VelFromFrame(start_velocity,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Update attitude values
	attitude = attitude_calculator.transform.basis
	torque = attitude_calculator.torque
	
	# If navigation mode and autopilot are engaged, fly along precalculated trajectory
	if propagator.planned_positions != null and nav_flag and autopilot_flag:
		# Find current index in the planned trajectory
		var i = find_time_index(propagator.planned_times,SystemTime.t)
		if i+2 > propagator.planned_times.size():
			# Disconnect autopilot and reset thrust
			integrate_normally(delta)
			auto_disc.emit()
			nav_disc.emit()
			thrust = 0
		else:
			# Linearly interpolate between points
			var dt = propagator.planned_times[i+1] - propagator.planned_times[i]
			var frac = (SystemTime.t - propagator.planned_times[i])/dt
			position = (1 - frac)*propagator.planned_positions[i] + frac*propagator.planned_positions[i+1]
			velocity = (1 - frac)*propagator.planned_velocities[i] + frac*propagator.planned_velocities[i+1]
			
			# Guess at acceleration
			planned_acceleration = (propagator.planned_velocities[i+1] - propagator.planned_velocities[i])/dt
			thrust = planned_acceleration.length()
		
	# Otherwise, integrate regularly
	else:
		integrate_normally(delta)
		
	
	
func integrate_normally(delta):
	# Change throttle setting
	if Input.is_action_just_pressed("full_throttle"):
		thrust = 0.05
	if Input.is_action_just_pressed("cut_throttle"):
		thrust = 0
	
	var dt = SystemTime.step*0.03333; # assumes 30 fps, replace with delta
	
	# Somehow get the acceleration from gravity in here
	var prev_gravity = propagator.Acceleration(position,SystemTime.prev_t)
	var gravity = propagator.Acceleration(position,SystemTime.t)
	
	# Calculate acceleration on vehicle
	var prev_acceleration = thrust*attitude.x + prev_gravity
	var acceleration = thrust*attitude.x + gravity
	
	var planet = get_parent().get_parent().get_node("Planets/Earth")
	# Calculate updated position and velocity through Verlet integration
	position = position + velocity*dt# + 0.5*prev_acceleration*previous_dt**2
	velocity = velocity + 1*(0*acceleration+prev_acceleration)*dt
	
	print(SystemTime.t,",",(position - planet.position).x)

func find_time_index(times,time):
	var index = 0
	for i in range(0,times.size()):
		if times[i] < time:
			index = i
	return index
