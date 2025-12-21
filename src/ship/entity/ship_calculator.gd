extends CharacterBody3D

@export var collidable = true

# State variables (global frame)
var acceleration = Vector3(0,0,0)
var attitude
var gravity_acceleration = Vector3(0,0,0) # just gravity
var thrust_acceleration = Vector3(0,0,0) # just thrust (all sources)

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

# State of avionics
var avionics = {
	"attitude_mode" : "",
	"attitude_inv" : false,
	"attitude_stab" : true,
	"autopilot" : false,
	"navigation" : false,
	"caution" : false,
	"warning" : false,
}

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

# Collider
@onready var shape_node: CollisionShape3D = $CollisionShape3D

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
	
	# Update attitude for collision shape
	shape_node.transform.basis = attitude
	
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
		# Update things periodically that don't need to accelerate with time warp
		navigation_calculator.update_periodically()
		
		# Do multiple simulation time steps per run of physics_process
		var sim_steps_per_physics_tick = clamp(SystemTime.step,1,100)
		gravity_acceleration = propagator.Acceleration(position,SystemTime.prev_t)
		for i in range(sim_steps_per_physics_tick):
			# Calculate simulation timestep
			var dt = SystemTime.step*delta/sim_steps_per_physics_tick
			
			# Process children processes that need to run with simulation
			navigation_calculator.update(dt, gravity_acceleration)
			attitude_calculator.update(dt)
			propulsion_calculator.update(dt)
			
			integrate_normally(dt, gravity_acceleration)
			
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
	thrust_acceleration = (thrust/1000.0)/total_mass # acceleration from all sources of thrust
	acceleration = attitude*thrust_acceleration + prev_gravity # current state depends on previous state
	
	# Euler integrate for position and velocity
	velocity = velocity + (acceleration)*dt
	var motion = velocity * dt
	
	var space_state = get_world_3d().direct_space_state
	
	# Build a query for our spacecraft's shape
	var shape = shape_node.shape
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = global_transform
	params.motion = motion
	params.collide_with_bodies = true
	params.collide_with_areas = false
	
	# Cast the shape forward to detect where it will hit
	# Returns safe and unsafe proportions of motion
	# var result = space_state.cast_motion(params)
	# var safe_proportion = result[0]
	# print(safe_proportion)
	
	# Check for current collisions
	var collision_info = space_state.get_rest_info(params)
	if collision_info and collidable:
		# Print the thing you just collided with
		var collider_id = collision_info["collider_id"]
		var collider = instance_from_id(collider_id)
		print(collider.name)
		
		# Get the relative velocity of the ship to the collider
		var collider_velocity = collision_info.linear_velocity
		var relative_velocity = velocity - collider_velocity
		
		# Check that the relative velocity is towards the collider
		# i.e. opposite the normal
		if relative_velocity.dot(collision_info.normal) < 0.0:
			# Reflect velocity about normal of collision
			var restitution = 0.1
			var reflected_relative_velocity = restitution*relative_velocity.bounce(collision_info.normal)
			
			# Get change in velocity and add to velocity
			var dv = reflected_relative_velocity - relative_velocity
			velocity += dv
			
			# Emit signal that you hit something
			collided.emit()
		
	position += motion

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
