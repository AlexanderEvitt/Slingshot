extends Node

var player_ship: PlayerShip

func _ready() -> void:
	# Tell the ShipData global how to reference the planets
	ShipData.sim_root = get_parent()
	
	# Load player ship into scene
	player_ship = preload("res://ship/entity/ship_entity.tscn").instantiate()
	add_child(player_ship)
	
	# Load save data if it exists
	var filename: String = "user://save%d.save" % [ShipData.slot]
	if FileAccess.file_exists(filename):
		# Load file
		var save_file: FileAccess = FileAccess.open(filename, FileAccess.READ)
		# Iterate through lines in the file
		while save_file.get_position() < save_file.get_length():
			var json_string: String = save_file.get_line()
			
			# Creates the helper class to interact with JSON.
			var json: JSON = JSON.new()

			# Check if there is any error while parsing the JSON string, skip in case of failure.
			var parse_result: Error = json.parse(json_string)
			if not parse_result == OK:
				print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
				continue

			# Get the data from the JSON object.
			var data: Dictionary = json.data
			
			# Disperse data to relevant objects
			if data["identifier"] == "SimTime":
				SimTime.t = data["t"]
			if data["identifier"] == "PlayerShip":
				player_ship.initialize(data)
	
	# Connect the save signal (comes from the pause menu)
	ShipData.save.connect(save_game)
	
	# Tell the ShipData global where its ship node is
	ShipData.player_ship = get_node("PlayerShip")

func save_game() -> void:
	# Get save file for writing
	var save_file: FileAccess = FileAccess.open("user://save%d.save" % [ShipData.slot], FileAccess.WRITE)
	
	# Get data from system time
	var system_time_data: Dictionary = {
		"identifier" : "SimTime",
		"t" : SimTime.t,
	}
	save_file.store_line(JSON.stringify(system_time_data))
	
	# Get data from player ship
	var player_ship_save_data: Dictionary = player_ship.save()
	save_file.store_line(JSON.stringify(player_ship_save_data))
	
