class_name PlayerShip
extends CharacterBody3D

@export var collidable := true

# State variables (global frame)
var acceleration := Vector3(0,0,0)
var attitude: Basis
var gravity_acceleration := Vector3(0,0,0) # just gravity
var thrust_acceleration := Vector3(0,0,0) # just thrust (all sources, ship frame)

# Engine variables
var torque := Vector3(0,0,0)
var thrust := Vector3(0,0,0)

# Vehicle mass
var dry_mass := 613280.0 # kg
var total_mass := dry_mass # kg (updated by propulsion)

# Children components
@onready var attitude_module: AttitudeModule = $AttitudeModule
@onready var navigation_module: NavigationModule = $NavigationModule
@onready var propulsion_module: PropulsionModule = $PropulsionModule
@onready var propagate_module: PropagateModule = $PropagateModule
@onready var plotter: Plotter = $Plotter
@onready var pointer: Node3D = $Pointer

# State of avionics
var avionics := {
	"attitude_mode" : "",
	"attitude_inv" : false,
	"attitude_stab" : true,
	"autopilot" : false,
	"navigation" : false,
	"caution" : false,
	"warning" : false,
}

# Waypoints
var waypoints: Array[Dictionary] = []

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
var berthed := true
# Path to station from sim_root (needed to save)
var station_path : String
# Nodes of station
var station : Station
var dock : Node3D
var berth : Node3D
# How far into the berth the docking point is
var berth_offset := Vector3(0.07,0,0)

# Tell the selection panel that this isn't a station you can dock with
var is_station := false


func _ready() -> void:
	# Initialize values
	attitude = attitude_module.transform.basis
	
	# Assign to random berth at Zephyr at start
	if berthed:
		assign_berth("SolarSystem/Earth/Zephyr/Station")
		berthed = true

func _physics_process(delta: float) -> void:
	# Update values for this iteration
	attitude = attitude_module.transform.basis
	torque = attitude_module.torque
	
	# Update attitude for collision shape
	shape_node.transform.basis = attitude
	
	# Update thrust
	thrust = propulsion_module.thrust
	
	# Update total vehicle mass
	total_mass = dry_mass + propulsion_module.he_quant + propulsion_module.de_quant
	
	# Attach ship to dock if docked
	if berthed:
		# Move ship with dock
		var berth_position: Vector3 = station.fetch(SimTime.t) + (berth.global_position - station.global_position) + berth.global_transform.basis*berth_offset
		position = berth_position
		velocity = station.fetch(SimTime.t) - station.fetch(SimTime.t - 1.0)
		attitude_module.transform.basis = berth.global_transform.basis

	# Integrate regularly
	else:
		# Update things periodically that don't need to accelerate with time warp
		navigation_module.update_periodically()
		
		# Do multiple simulation time steps per run of physics_process
		var sim_steps_per_physics_tick: float = clamp(SimTime.step,1,100)
		gravity_acceleration = propagate_module.Acceleration(position,SimTime.prev_t)
		for i in range(sim_steps_per_physics_tick):
			# Calculate simulation timestep
			var dt: float = SimTime.step*delta/sim_steps_per_physics_tick
			
			# Process children processes that need to run with simulation
			navigation_module.update(dt, gravity_acceleration)
			attitude_module.update(dt)
			propulsion_module.update(dt)
			
			integrate_normally(dt, gravity_acceleration)
			
		# Dock/undock if key is pressed
	if Input.is_action_just_pressed("dock"):
		if berthed:
			berthed = false
			rel_clamp.emit()
		elif !berthed:
			var berth_position: Vector3 = station.fetch(SimTime.t) + (berth.global_position - station.global_position) + berth.global_transform.basis*berth_offset
			var berth_error: float = (berth_position - position).length()
			# Allow docking only within five meters
			if berth_error < 0.005:
				berthed = true
				att_clamp.emit()
				
	# Pass attitude to pointer
	pointer.transform.basis = attitude
	
	# Pass plotter position to plotter (it's a C# module)
	plotter.positions = propagate_module.get("plotted_positions")

func integrate_normally(dt: float, prev_gravity: Vector3) -> void:
	# Calculate acceleration on vehicle
	thrust_acceleration = (thrust/1000.0)/total_mass # acceleration from all sources of thrust
	acceleration = attitude*thrust_acceleration + prev_gravity # current state depends on previous state
	
	# Euler integrate for position and velocity
	velocity = velocity + (acceleration)*dt
	var motion: Vector3 = velocity * dt
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	# Build a query for our spacecraft's shape
	var shape: Shape3D = shape_node.shape
	var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
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
	var collision_info: Dictionary = space_state.get_rest_info(params)
	if collision_info and collidable:
		# Print the thing you just collided with
		var collider_id: int = collision_info["collider_id"]
		var collider: Node = instance_from_id(collider_id)
		print(collider.name)
		
		# Get the relative velocity of the ship to the collider
		var collider_velocity: Vector3 = collision_info.linear_velocity
		var relative_velocity: Vector3 = velocity - collider_velocity
		
		# Check that the relative velocity is towards the collider
		# i.e. opposite the normal
		var collision_normal: Vector3 = collision_info.normal
		if relative_velocity.dot(collision_normal) < 0.0:
			# Reflect velocity about normal of collision
			var restitution := 0.1
			var reflected_relative_velocity: Vector3 = restitution*relative_velocity.bounce(collision_normal)
			
			# Get change in velocity and add to velocity
			var dv: Vector3 = reflected_relative_velocity - relative_velocity
			velocity += dv
			
			# Emit signal that you hit something
			collided.emit()
		
	position += motion

func fetch(_time: float) -> Vector3:
	# Return origin of ship frame
	return position

func assign_berth(new_station: String) -> void:
	# Called by selection_panel.gd with the name of the new_station (path to station underneath body)
	
	# Make sure you're undocked so you don't move to the berth
	berthed = false
	
	# Get the station (the child of the Body that represents the station)
	station_path = new_station
	station = ShipData.sim_root.get_node(station_path)
	
	# Get the berth_path of the station (contains info on finding the berth node)
	# this is relative to the station
	var local_berth_path: String = station.berth_path
	var split_path: PackedStringArray = local_berth_path.split("/{}/")
	
	# Get port component (parent to all docks)
	var port_path: String = split_path[0]
	var port: Node3D = station.get_node(port_path)
	
	# Get random dock
	var docks: Array[Node] = port.get_children()
	dock = docks[randi_range(0, len(docks) - 1)]
	
	# Get parent node to all berths (child of selected dock)
	var berth_parent: Node3D = dock.get_node(split_path[1])
	
	# Get random berth
	var berths: Array[Node] = berth_parent.get_children()
	berth = berths[randi_range(0, len(berths) - 1)]
	berth_updated.emit()
	
# Function that generates what data to save
func save() -> Dictionary:
	var save_dict: Dictionary = {
		"identifier" : "PlayerShip",
		"position_x" : position.x,
		"position_y" : position.y,
		"position_z" : position.z,
		"velocity_x" : velocity.x,
		"velocity_y" : velocity.y,
		"velocity_z" : velocity.z,
		"rotation_x" : attitude_module.rotation.x,
		"rotation_y" : attitude_module.rotation.y,
		"rotation_z" : attitude_module.rotation.z,
		"berthed" : berthed,
		"station_path" : station_path,
	}
	return save_dict

# Function that loads from a save file
func initialize(save_dict: Dictionary) -> void:
	# Load state data from dictionary
	var px: float = save_dict.get("position_x", 0.0)
	var py: float = save_dict.get("position_y", 0.0)
	var pz: float = save_dict.get("position_z", 0.0)

	var vx: float = save_dict.get("velocity_x", 0.0)
	var vy: float = save_dict.get("velocity_y", 0.0)
	var vz: float = save_dict.get("velocity_z", 0.0)

	position = Vector3(px, py, pz)
	velocity = Vector3(vx, vy, vz)

	attitude_module.rotation.x = save_dict.get("rotation_x", 0.0)
	attitude_module.rotation.y = save_dict.get("rotation_y", 0.0)
	attitude_module.rotation.z = save_dict.get("rotation_z", 0.0)

	# Initialize at station from save file
	var saved_station_path: String = save_dict.get("station_path", NodePath(""))
	assign_berth(saved_station_path)
	berthed = save_dict.get("berthed", false)
