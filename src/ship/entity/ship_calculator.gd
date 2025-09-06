extends Node3D

var velocity
var attitude

var torque
var thrust = Vector3(0,0,0)
var throttle = 0

var plotted_positions

@export var start_position : Vector3
@export var start_velocity : Vector3

@onready var attitude_calculator = $AttitudeCalculator
@onready var navigation_calculator = $NavigationCalculator
@onready var propulsion_calculator = $PropulsionCalculator
@onready var collision_calculator = $CollisionCalculator
@onready var propagator = $Propagator

# Autopilot modes
var current_mode
var inv_flag
var stab_flag
var autopilot_flag
var nav_flag

# Waypoints
var waypoints = []

# Signals
signal auto_disc
signal nav_disc
signal rel_clamp
signal collision
signal waypoints_updated

var previous_dt = 0.03333
var previous_t = 0

var mass = 1

var docked = true
@onready var dock = get_node("../../Planets/Earth/ZephyrStation/DockCenter")

# this module moves data from the master scene to an autoload where others can access it

func _ready():
	# Initialize values
	attitude = attitude_calculator.transform.basis
	position = Conversions.ToUniversal(start_position,0)
	velocity = Conversions.VelFromFrame(start_velocity,0)

func _physics_process(delta):
	# Update values for this iteration
	attitude = attitude_calculator.transform.basis
	torque = attitude_calculator.torque
	
	# Update thrust
	thrust = propulsion_calculator.thrust
	throttle = propulsion_calculator.throttle

	# Fix to start position if still docked
	if docked:
		position = dock.get_parent().fetch(SystemTime.t) + dock.get_parent().transform.basis*dock.position
		velocity = (dock.get_parent().fetch(SystemTime.t) - dock.get_parent().fetch(SystemTime.t - 1.0))
		if Input.is_action_just_pressed("dock"):
			docked = false
			rel_clamp.emit() # show alert
	# Integrate regularly
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


func find_time_index(times,time):
	var index = 0
	for i in range(0,times.size()):
		if times[i] < time:
			index = i
	return index

func fetch(_time):
	# Return origin of ship frame
	# So if you select the ship frame, you basically just get the trajectory relative to wherever you are right now
	return position
