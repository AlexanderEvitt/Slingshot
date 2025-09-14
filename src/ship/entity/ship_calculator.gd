extends Node3D

# State variables
var velocity
var attitude

# Engine variables
var torque
var thrust = Vector3(0,0,0)
var throttle = 0

# Children components
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
signal nav_next
signal att_clamp
signal rel_clamp
signal collision
signal waypoints_updated
signal berth_updated

# Mass currently only for collision impulse
var mass = 1

# Which berth to start at (updated)
var berthed = true
@onready var station = get_tree().root.get_node("GameRoot/Planets/Earth/ZephyrStation")
@onready var dock = station.get_node("Shipyard/DockC")
@onready var berth = dock.get_node("Berth4")
var berth_offset = Vector3(0.1,0,0)


func _ready():
	# Initialize values
	attitude = attitude_calculator.transform.basis

func _physics_process(delta):
	# Update values for this iteration
	attitude = attitude_calculator.transform.basis
	torque = attitude_calculator.torque
	
	# Update thrust
	thrust = propulsion_calculator.thrust
	throttle = propulsion_calculator.throttle

	# Attach ship to dock if docked
	if berthed:
		# Move ship with dock
		position = station.fetch(SystemTime.t) + (berth.global_position - station.global_position) + berth.global_transform.basis*berth_offset
		velocity = station.fetch(SystemTime.t) - station.fetch(SystemTime.t - 1.0)
		attitude_calculator.transform.basis = berth.global_transform.basis

	# Integrate regularly
	else:
		# Do multiple simulation time steps per run of physics_process
		var sim_steps_per_physics_tick = clamp(SystemTime.step,1,100)
		var prev_gravity = propagator.Acceleration(position,SystemTime.prev_t)
		for i in range(sim_steps_per_physics_tick):
			# Calculate simulation timestep
			var dt = SystemTime.step*delta/sim_steps_per_physics_tick
			
			# Process children processes that need to run with simulation
			navigation_calculator.update(dt, prev_gravity)
			attitude_calculator.update(dt)
			propulsion_calculator.update(dt)
			
			integrate_normally(dt, prev_gravity)
			
		# Dock/undock if key is pressed
	if Input.is_action_just_pressed("dock"):
		if berthed:
			berthed = false
			rel_clamp.emit()
		elif !berthed:
			var berth_position = station.fetch(SystemTime.t) + (berth.global_position - station.global_position)
			var berth_error = (berth_position - position).length()
			# Allow docking only within ten meters
			if berth_error < 0.01:
				berthed = true
				att_clamp.emit()

func integrate_normally(dt, prev_gravity):
	# Somehow get the acceleration from gravity in here
	# var gravity = propagator.Acceleration(position,SystemTime.t)
	
	# Calculate acceleration on vehicle
	var prev_acceleration = attitude*thrust + prev_gravity
	# var acceleration = attitude*thrust + gravity
	
	# Euler integrate for position and velocity
	position = position + velocity*dt
	velocity = velocity + (prev_acceleration)*dt
	
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
	return position

func assign_berth(new_station):
	# Make sure you're undocked so you don't move to the berth
	berthed = false
	
	# Assign station
	station = get_tree().root.get_node("GameRoot/" + new_station)
	
	# Get shipyard (parent to all dock)
	var shipyard = get_tree().root.get_node("GameRoot/" + new_station + "/Shipyard")
	
	# Get random dock
	var docks = shipyard.get_children()
	dock = docks[randi_range(0, len(docks) - 1)]
	
	# Get random berth
	var berths = dock.get_children()
	berth = berths[randi_range(0, len(berths) - 1)]
	berth_updated.emit()
