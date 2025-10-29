extends Node3D

# Scenes that are the berths
var current_berth = null

# Body that this is a child of
@onready var body = get_parent()

# Path from station (self) to specific berth
# First {} is the dock name
# Second {} is the berth name
@export var berth_path := "shipyard/Port/{}/docks/Docks/{}/"

func _ready():
	# Connect the loading and unloading to the signal emitted by the ship
	ShipData.player_ship.berth_updated.connect(update_berth)
	
	# Run update berth so its already loaded in at game start
	update_berth()
	
func _physics_process(_delta):
	# Pass the velocity to the berth (for collider)
	if current_berth != null:
		current_berth.get_child(0).set_velocity(fetch_velocity(SystemTime.t))

func update_berth():
	# Load the berth meshes
	var full_berth = preload("res://bodies/stations/components/berth.tscn").instantiate()
	var simplified_berth = preload("res://bodies/stations/components/simplified_berth.tscn").instantiate()

	# Only run this if the ship's station is this station
	if ShipData.player_ship.station == self:
		# Remove the berth from the current berth
		if current_berth != null:
			current_berth.get_child(0).queue_free()
		
		# Replace the current_berth with a simplified berth
		if current_berth != null:
			current_berth.add_child(simplified_berth)
		
		# Figure out what the new berth is
		var new_berth = ShipData.player_ship.berth
		current_berth = new_berth
		
		# Remove the new berth's simplified berth
		if current_berth != null:
			current_berth.get_child(0).queue_free()
		
		# Add a berth to the new berth
		if current_berth != null:
			current_berth.add_child(full_berth)

# Fetch the state of the parent body when asked
func fetch(time):
	return body.fetch(time)

func fetch_velocity(time):
	return body.fetch_velocity(time)
