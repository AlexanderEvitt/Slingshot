extends Node

var player_ship

func _ready() -> void:

	# Tell the ShipData global how to reference the planets
	ShipData.sim_root = get_parent()
	Conversions.sim_root = get_parent()
	
	# Load ship physics entity
	player_ship = preload("res://ship/entity/ship_entity.tscn").instantiate()

	add_child(player_ship)
	
	# If save game exists, load the data into the ship
	ShipData.save.connect(save_game)
	
	# Tell the ShipData global where its ship node is
	ShipData.player_ship = get_node("PlayerShip")

func save_game():
	# Get save file for writing
	var save_file = FileAccess.open("user://save%d.save" % [ShipData.slot], FileAccess.WRITE)
	
	# Get data from system time
	var system_time_data = {
		"SystemTime_t" : SystemTime.t,
	}
	save_file.store_line(JSON.stringify(system_time_data))
	
	# Get data from player ship
	var player_ship_save_data = player_ship.save()
	save_file.store_line(JSON.stringify(player_ship_save_data))
	
