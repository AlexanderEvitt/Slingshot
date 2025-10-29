extends CharacterBody3D

# State variables (global frame)
var acceleration = Vector3(0,0,0)
var attitude

# Engine variables
var torque
var thrust = Vector3(0,0,0)

# Vehicle mass
var dry_mass = 613280 # kg
var total_mass = dry_mass # kg (updated by propulsion)

# Children components
@onready var attitude_calculator = $AttitudeCalculator
@onready var navigation_calculator = $NavigationCalculator
@onready var propulsion_calculator = $PropulsionCalculator
@onready var propagator = $Propagator
@onready var plotter = $Plotter
@onready var pointer = $Pointer

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
signal collided
signal waypoints_updated
signal berth_updated

# Mass only for collision impulse
var mass = 1

# Data on where you are docked
var berthed = true
# Path to station from sim_root (needed to save)
var station_path : String
# Nodes of station
var station : Node # station component (underneath Body.cs)
var dock : Node
var berth : Node
# How far into the berth the docking point is
var berth_offset = Vector3(0.07,0,0)

# Tell the selection panel that this isn't a station you can dock with
var is_station = false


func _ready():
	# Initialize values
	attitude = attitude_calculator.transform.basis
	
	# Assign to random berth at Zephyr at start
	if berthed:
		assign_berth("SolarSystem/Earth/Zephyr/Station")
		berthed = true

func _physics_process(delta):
	# Update values for this iteration
	attitude = attitude_calculator.transform.basis
	torque = attitude_calculator.torque
	
	# Update thrust
	thrust = propulsion_calculator.thrust
	
	# Update total vehicle mass
	total_mass = dry_mass + propulsion_calculator.he_quant + propulsion_calculator.de_quant
	
	# Attach ship to dock if docked
	if berthed:
		# Move ship with dock
		var berth_position = station.fetch(SystemTime.t) + (berth.global_position - station.global_position) + berth.global_transform.basis*berth_offset
		position = berth_position
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
			var berth_position = station.fetch(SystemTime.t) + (berth.global_position - station.global_position) + berth.global_transform.basis*berth_offset
			var berth_error = (berth_position - position).length()
			# Allow docking only within five meters
			if berth_error < 0.005:
				berthed = true
				att_clamp.emit()
				
	# Pass attitude to pointer
	pointer.transform.basis = attitude
	
	# Pass plotter position to plotter
	plotter.positions = propagator.plotted_positions

func integrate_normally(dt, prev_gravity):
	# Calculate acceleration on vehicle
	var thrust_acceleration = (thrust/1000.0)/total_mass # acceleration from all sources of thrust
	acceleration = attitude*thrust_acceleration + prev_gravity # current state depends on previous state
	
	# Euler integrate for position and velocity
	var new_velocity = velocity + (acceleration)*dt
	var motion = new_velocity * dt
	
	# Get collision data
	var result = test_move(global_transform, motion, null, 0.001, true)
	if result == true:
		print("Resulting")
	var collision = move_and_collide(motion, false, 0.001, true, 1)
	
	if collision != null:
		print("Colliding:")
		_handle_collision(collision, new_velocity, dt)
	else:
		# No collision, update velocity
		velocity = new_velocity

func _handle_collision(collision: KinematicCollision3D, new_velocity: Vector3, _dt: float):
	# Get collider normal
	var normal = collision.get_normal()
	
	# Velocity of ship relative to collider
	var colliding_velocity = collision.get_collider_velocity()
	print("	colliding_velocity: ", colliding_velocity)
	
	# Bounce velocity off collider
	var reflected_velocity = colliding_velocity.bounce(normal)
	print("	reflected_velocity: ", reflected_velocity)
	
	# Apply restitution (bounciness)
	var restitution = 0.3
	reflected_velocity = reflected_velocity * restitution
	
	# Get collision change in velocity
	var dv = reflected_velocity - colliding_velocity
	
	# Add change in velocity
	print("	dv", dv)
	velocity = new_velocity + dv
	print("	velocity: ", velocity)

	# Update position to the contact point (prevents tunneling)
	# position = collision.get_position()

func fetch(_time):
	# Return origin of ship frame
	return position

func assign_berth(new_station):
	# Called by selection_panel.gd with the name of the new_station (path to station underneath body)
	
	# Make sure you're undocked so you don't move to the berth
	berthed = false
	
	# Get the station (the child of the Body that represents the station)
	station_path = new_station
	station = ShipData.sim_root.get_node(station_path)
	
	# Get the berth_path of the station (contains info on finding the berth node)
	# this is relative to the station
	var local_berth_path = station.berth_path
	var split_path = local_berth_path.split("/{}/")
	
	# Get port component (parent to all docks)
	var port_path = split_path[0]
	var port = station.get_node(port_path)
	
	# Get random dock
	var docks = port.get_children()
	dock = docks[randi_range(0, len(docks) - 1)]
	
	# Get parent node to all berths (child of selected dock)
	var berth_parent = dock.get_node(split_path[1])
	
	# Get random berth
	var berths = berth_parent.get_children()
	berth = berths[randi_range(0, len(berths) - 1)]
	berth_updated.emit()
	
# Function that generates what data to save
func save():
	var save_dict = {
		"identifier" : "PlayerShip",
		"position_x" : position.x,
		"position_y" : position.y,
		"position_z" : position.z,
		"velocity_x" : velocity.x,
		"velocity_y" : velocity.y,
		"velocity_z" : velocity.z,
		"rotation_x" : attitude_calculator.rotation.x,
		"rotation_y" : attitude_calculator.rotation.y,
		"rotation_z" : attitude_calculator.rotation.z,
		"berthed" : berthed,
		"station_path" : station_path,
	}
	return save_dict

# Function that loads from a save file
func initialize(save_dict):
	# State info
	position = Vector3(save_dict["position_x"],save_dict["position_y"],save_dict["position_z"])
	velocity = Vector3(save_dict["velocity_x"],save_dict["velocity_y"],save_dict["velocity_z"])
	
	# Attitude info
	attitude_calculator.rotation.x = save_dict["rotation_x"]
	attitude_calculator.rotation.y = save_dict["rotation_y"]
	attitude_calculator.rotation.z = save_dict["rotation_z"]
	
	# Docking info
	assign_berth(save_dict["station_path"])
	berthed = save_dict["berthed"]
