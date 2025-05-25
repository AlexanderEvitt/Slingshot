extends Node3D

var velocity
var attitude

var torque
var thrust = Vector3(0,0,0)
var throttle = 0

var propagator
var plotted_positions

@export var start_position : Vector3
@export var start_velocity : Vector3

var attitude_calculator
var thrust_calculator
var collision_calculator

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
signal rel_clamp
signal collision

var previous_dt = 0.03333
var previous_t = 0

var mass = 1

var docked = true
@onready var dock = get_node("../../Planets/Earth/ZephyrStationMain/DockCenter")

# this module moves data from the master scene to an autoload where others can access it

func _ready():
	attitude_calculator = get_node("AttitudeCalculator")
	thrust_calculator = get_node("Thrusters")
	collision_calculator = get_node("CollisionDetector")
	propagator = get_node("Propagator")
	
	# Initialize values
	attitude = attitude_calculator.transform.basis
	position = Conversions.ToUniversal(start_position,0)
	velocity = Conversions.VelFromFrame(start_velocity,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Update values for this iteration
	attitude = attitude_calculator.transform.basis
	torque = attitude_calculator.torque
	
	# Update thrust
	thrust = thrust_calculator.thrust
	throttle = thrust_calculator.throttle
	
	# If navigation mode and autopilot are engaged, fly along precalculated trajectory
	if propagator.planned_positions != null and nav_flag and autopilot_flag:
		# Find current index in the planned trajectory
		var i = find_time_index(propagator.planned_times,SystemTime.t)
		if i+2 > propagator.planned_times.size():
			# Disconnect autopilot and reset thrust
			integrate_normally(delta)
			auto_disc.emit()
			nav_disc.emit()
			thrust = Vector3(0,0,0)
		else:
			move_by_plan()
		
	# Otherwise, integrate regularly
	else:
		# Do multiple simulation time steps per run of physics_process
		# Allow max timestep of 1000*(1/30) s
		# Do one sim step per physics step up to step = 100, then increase
		# Also say no more than max 100 steps per step
		var sim_steps_per_physics_tick = clamp(SystemTime.step/100,1,100)
		for i in range(sim_steps_per_physics_tick):
			# Calculate simulation timestep
			var dt = SystemTime.step*delta/sim_steps_per_physics_tick
			integrate_normally(dt)
		
	# Fix to start position if still docked
	if docked:
		position = dock.get_parent().fetch(SystemTime.t) + dock.get_parent().transform.basis*dock.position
		velocity = (dock.get_parent().fetch(SystemTime.t) - dock.get_parent().fetch(SystemTime.t - SystemTime.step))
	if Input.is_action_just_pressed("dock"):
		docked = false
		rel_clamp.emit() # show alert

func integrate_normally(dt):
	# Somehow get the acceleration from gravity in here
	var prev_gravity = propagator.Acceleration(position,SystemTime.prev_t)
	var gravity = propagator.Acceleration(position,SystemTime.t)
	
	# Calculate acceleration on vehicle
	var prev_acceleration = attitude*thrust + prev_gravity
	var acceleration = attitude*thrust + gravity
	
	# Calculate updated position and velocity through Verlet integration
	position = position + velocity*dt# + 0.5*prev_acceleration*previous_dt**2
	velocity = velocity + 1*(0*acceleration+prev_acceleration)*dt
	
	# Change the velociity by the impulse
	velocity += collision_calculator.impulse/mass
	
	# Emit collision alarm if there's impulse
	if collision_calculator.impulse.length_squared() > 0:
		collision.emit()

func move_by_plan():
	var i = find_time_index(propagator.planned_times,SystemTime.t)
	# Linearly interpolate between points
	var dt = propagator.planned_times[i+1] - propagator.planned_times[i]
	var frac = (SystemTime.t - propagator.planned_times[i])/dt
	position = (1 - frac)*propagator.planned_positions[i] + frac*propagator.planned_positions[i+1]
	velocity = (1 - frac)*propagator.planned_velocities[i] + frac*propagator.planned_velocities[i+1]
	
	# Guess at acceleration
	planned_acceleration = (propagator.planned_velocities[i+1] - propagator.planned_velocities[i])/dt
	throttle = planned_acceleration.length()
	thrust = planned_acceleration


func find_time_index(times,time):
	var index = 0
	for i in range(0,times.size()):
		if times[i] < time:
			index = i
	return index
