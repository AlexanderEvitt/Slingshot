extends Node3D

# Scenes that are the berths
var current_berth = null

func _ready():
	# Connect the loading and unloading to the signal emitted by the ship
	ShipData.player_ship.berth_updated.connect(update_berth)
	
	# Run update berth so its already loaded in at game start
	update_berth()

func update_berth():
	# Load the berth meshes
	var full_berth = preload("res://bodies/stations/components/berth.tscn").instantiate()
	var simplified_berth = preload("res://bodies/stations/components/simplified_berth.tscn").instantiate()

	# Remove the berth from the current berth
	if current_berth != null:
		current_berth.get_child(0).queue_free()
	
	# Replace the current_berth with a simplified berth
	if current_berth != null:
		current_berth.add_child(simplified_berth)
	
	# Figure out what the new berth is
	var dock_name = ShipData.player_ship.dock.name
	var berth_name = ShipData.player_ship.berth.name
	current_berth = get_node("Port/" + dock_name + "/docks/Docks/" + berth_name)
	
	# Remove the new berth's simplified berth
	if current_berth != null:
		current_berth.get_child(0).queue_free()
	
	# Add a berth to the new berth
	if current_berth != null:
		current_berth.add_child(full_berth)
