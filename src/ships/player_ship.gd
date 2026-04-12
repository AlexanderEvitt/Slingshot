class_name PlayerShip
extends RigidBody3D

# State variables (system frame)
# position & velocity are in floating reference frame
var system_position := Vector3(0,0,0)
var system_velocity := Vector3(0,0,0)
var acceleration := Vector3(0,0,0)
var attitude: Basis
var gravity_acceleration := Vector3(0,0,0) # just gravity
var thrust_acceleration := Vector3(0,0,0) # just thrust (all sources, ship frame)
var force := Vector3(0,0,0) # all forces applied to vehicle

# Engine variables
var torque := Vector3(0,0,0)
var thrust := Vector3(0,0,0)

# Vehicle mass
var dry_mass := 613280.0 # kg

# Children components
@onready var attitude_module: AttitudeModule = $AttitudeModule
@onready var navigation_module: NavigationModule = $NavigationModule
@onready var propulsion_module: PropulsionModule = $PropulsionModule
@onready var propagate_module: PropagateModule = $PropagateModule
@onready var plotter: Plotter = $Plotter

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

var prev_velocity := Vector3(0,0,0)

func _ready() -> void:
	# Initialize values
	attitude = attitude_module.transform.basis
	
	# Assign to random berth at Zephyr at start
	if berthed:
		assign_berth("SolarSystem/Jupiter/Europa/Concordia/Station")
		berthed = true

func _physics_process(delta: float) -> void:
	# Update values for this iteration
	torque = attitude_module.torque
	#print(system_position.length())
	
	# Update thrust
	thrust = propulsion_module.thrust
	
	# Update total vehicle mass
	mass = dry_mass + propulsion_module.he_quant + propulsion_module.de_quant
	
	# Attach ship to dock if docked
	if berthed:
		pass

	# Integrate regularly
	else:
		# Update things periodically that don't need to accelerate with time warp
		navigation_module.update_periodically()
		
		# Do multiple simulation time steps per run of physics_process
		var sim_steps_per_physics_tick: float = clamp(SimTime.step,1,100)
		gravity_acceleration = propagate_module.Acceleration(system_position,SimTime.prev_t)
		for i in range(sim_steps_per_physics_tick):
			# Calculate simulation timestep
			var dt: float = SimTime.step*delta/sim_steps_per_physics_tick
			
			# Process children processes that need to run with simulation
			navigation_module.update(dt, gravity_acceleration)
			attitude_module.update(dt)
			propulsion_module.update(dt)
			
		# Dock/undock if key is pressed
	if Input.is_action_just_pressed("dock"):
		if berthed:
			berthed = false
			rel_clamp.emit()
		elif !berthed:
			var berth_position: Vector3 = station.fetch(SimTime.t) + (berth.global_position - station.global_position) + berth.global_transform.basis*berth_offset
			var berth_error: float = (berth_position - system_position).length()
			# Allow docking only within five meters
			if berth_error < 5.0:
				berthed = true
				att_clamp.emit()
	
	# Pass plotter position to plotter (it's a C# module)
	plotter.positions = propagate_module.get("plotted_positions")

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if state.get_contact_count() > 0:
		#print("Contacts: ", state.get_contact_count())
		#print("  Position: ", state.get_contact_local_position(0))
		#print("  Normal: ", state.get_contact_local_normal(0))
		#print("  Collider: ", state.get_contact_collider_object(0).constant_linear_velocity)
		if state.get_contact_collider_object(0).constant_linear_velocity.length() > 0.01:
			print("Alarm!")
			print(state.get_contact_collider_object(0).constant_linear_velocity.length())
	gravity_acceleration = propagate_module.Acceleration(system_position,SimTime.prev_t)
	#print(state.transform.origin.length())
	force = attitude*(thrust/1000.0) + mass*gravity_acceleration
	acceleration = force/mass # for ui

	if berthed:
		state.linear_velocity = Vector3(0,0,0)
		state.transform.origin = Vector3(0,0,0)
		# Move ship with dock
		# Set system state values, lock position and velocity to these
		var berth_position: Vector3 = station.fetch(SimTime.t) + (berth.global_position - station.global_position) + berth.global_transform.basis*berth_offset
		system_position = berth_position
		system_velocity = station.fetch(SimTime.t) - station.fetch(SimTime.t - 1.0)
		attitude = berth.global_transform.basis
		state.transform.basis = attitude
		# Fix floating frame to ship every frame
		ShipData.floating_frame_position = system_position
		ShipData.floating_frame_velocity = system_velocity
		ShipData.floating_frame_time = SimTime.t
	elif SimTime.step == 1.0:
		custom_integrator = false
		
		state.apply_central_force(force)
		state.apply_torque(torque)
		attitude = state.transform.basis
		#print("Integrated!")
	else:
		custom_integrator = true
		# Calculate acceleration on vehicle
		# Euler integrate position
		state.linear_velocity = state.linear_velocity + acceleration*SimTime.step*state.step
		state.transform.origin = state.transform.origin + state.linear_velocity*SimTime.step*state.step
		# Take target attitude from attitude_module
		attitude = attitude_module.target_transform
		state.transform.basis = attitude
	
	if !berthed:
		# Update system variables for external use
		system_position = state.transform.origin + ShipData.get_floating_frame_origin()
		system_velocity = state.linear_velocity + ShipData.floating_frame_velocity
	
	# Reset floating frame when vehicle strays too far
	if state.transform.origin.length() > 1.0 or state.linear_velocity.length() > 1.0:
		# Assign new origin coords
		ShipData.floating_frame_position = system_position
		ShipData.floating_frame_velocity = system_velocity
		ShipData.floating_frame_time = SimTime.t
		
		# Update vehicle coords
		state.transform.origin = system_position - ShipData.get_floating_frame_origin()
		state.linear_velocity = system_velocity - ShipData.floating_frame_velocity
		print("Reinit: ", state.transform.origin.length(), " ", state.linear_velocity.length())
		

func fetch(_time: float) -> Vector3:
	# Return origin of ship frame
	return system_position

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
		"position_x" : system_position.x,
		"position_y" : system_position.y,
		"position_z" : system_position.z,
		"velocity_x" : system_velocity.x,
		"velocity_y" : system_velocity.y,
		"velocity_z" : system_velocity.z,
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

	system_position = Vector3(px, py, pz)
	system_velocity = Vector3(vx, vy, vz)
	position = system_position
	linear_velocity = system_velocity

	attitude_module.rotation.x = save_dict.get("rotation_x", 0.0)
	attitude_module.rotation.y = save_dict.get("rotation_y", 0.0)
	attitude_module.rotation.z = save_dict.get("rotation_z", 0.0)

	# Initialize at station from save file
	var saved_station_path: String = save_dict.get("station_path", NodePath(""))
	assign_berth(saved_station_path)
	berthed = save_dict.get("berthed", false)
