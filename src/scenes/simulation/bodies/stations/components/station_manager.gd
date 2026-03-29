class_name Station
extends Node3D

# Scenes that are the berths
var current_berth: Node3D = null

# Body that this is a child of
@onready var body: Body = get_parent()

# Path from station (self) to specific berth
# First {} is the dock name
# Second {} is the berth name
@export var berth_path := "shipyard/Port/{}/docks/Docks/{}/"

func _ready() -> void:
	# Connect the loading and unloading to the signal emitted by the ship
	ShipData.player_ship.berth_updated.connect(update_berth)
	
	# Run update berth so its already loaded in at game start
	update_berth()
	
func _physics_process(_delta: float) -> void:
	# Pass the velocity to the berth (for collider)
	if current_berth != null and current_berth.get_child(0).name == "berth":
		var body_collider: Berth = current_berth.get_child(0)
		body_collider.set_velocity(fetch_velocity(SimTime.t) - ShipData.floating_frame_velocity)

func update_berth() -> void:
	# Load the berth meshes
	var full_berth: Berth = preload("res://scenes/simulation/bodies/stations/components/berth.tscn").instantiate()
	var simplified_berth: Node3D = preload("res://scenes/simulation/bodies/stations/components/simplified_berth.tscn").instantiate()

	# Only run this if the ship's station is this station
	if ShipData.player_ship.station == self:
		# Remove the berth from the current berth
		if current_berth != null:
			current_berth.get_child(0).queue_free()
		
		# Replace the current_berth with a simplified berth
		if current_berth != null:
			current_berth.add_child(simplified_berth)
		
		# Figure out what the new berth is
		var new_berth: Node3D = ShipData.player_ship.berth
		current_berth = new_berth
		
		# Remove the new berth's simplified berth
		if current_berth != null:
			current_berth.get_child(0).queue_free()
		
		# Add a berth to the new berth
		if current_berth != null:
			current_berth.add_child(full_berth)
			
		# Attach clamps if you're already docked
		if ShipData.player_ship.berthed:
			full_berth.attach_clamps()

# Fetch the state of the parent body when asked
func fetch(time: float) -> Vector3:
	return body.fetch(time)

func fetch_velocity(time: float) -> Vector3:
	return body.fetch_velocity(time)
