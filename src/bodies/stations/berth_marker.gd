extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Update berth whenever ship says so
	ShipData.player_ship.berth_updated.connect(on_berth_updated)
	# and also at startup
	on_berth_updated()

# Sets up the berth marker
func on_berth_updated():
	# Get new berth from station manager
	var station = ShipData.player_ship.station
	# Only do this if the station is this one
	if station.get_parent() == ShipData.sim_root.get_node(get_parent().body_path):
		var berth = ShipData.player_ship.station.current_berth
		
		# Place berth at appropriate relative transform
		if berth == null:
			visible = false
		else:
			visible = true
			position = berth.global_position - station.global_position
			transform.basis = berth.global_transform.basis
	else:
		visible = false
