extends MarginContainer


@onready var waypoint_row := preload("res://ui/screens/navigation/waypoints/waypoint_row.tscn")
@onready var waypoints_list := $VBoxContainer/MainPanel/ScrollContainer/MarginContainer/Box/WaypointsList
@onready var next_button: Button = $VBoxContainer/MainPanel/ScrollContainer/MarginContainer/Box/NextButton
@onready var clear_button: Button = $VBoxContainer/MainPanel/ScrollContainer/MarginContainer/Box/ClearButton

func _ready() -> void:
	# Update waypoints list when ship signals that the waypoints are new
	ShipData.player_ship.waypoints_updated.connect(update_waypoint)
	ShipData.player_ship.nav_next.connect(update_waypoint)
	
	# Connect clear and next buttons
	next_button.pressed.connect(next_waypoint)
	clear_button.pressed.connect(clear_waypoints)

func update_waypoint() -> void:
	# Purge all children rows
	for child in waypoints_list.get_children():
		child.queue_free()
	
	# Add each new row
	var i := 0
	for p in ShipData.player_ship.waypoints:
		# Instantiate a new waypoint_row
		var this_waypoint_row := waypoint_row.instantiate()
		
		# Set the from/to flag
		var flag_label: Label = this_waypoint_row.get_node("Flag")
		if i == ShipData.player_ship.navigation_module.active_waypoint:
			flag_label.text = "FR"
		elif i == ShipData.player_ship.navigation_module.active_waypoint + 1:
			flag_label.text = "TO"
		else:
			flag_label.text = "  "
		
		# Update the telemetry of it
		var number_label: Label = this_waypoint_row.get_node("Number")
		var frame_label: Label = this_waypoint_row.get_node("Frame")
		var distance_label: Label = this_waypoint_row.get_node("Distance")
		number_label.text = str(i)
		frame_label.text = p["Frame"].name
		var r_waypoint: Vector3 = p["Position"]
		distance_label.text = to_hud_string(r_waypoint.length(), "a")
		
		# Add it to the tree
		waypoints_list.add_child(this_waypoint_row)
		i = i + 1

func next_waypoint() -> void:
	if len(ShipData.player_ship.waypoints) > 1:
		# Update navigation calculator's active_waypoint value with wrapping
		ShipData.player_ship.navigation_module.active_waypoint = (ShipData.player_ship.navigation_module.active_waypoint + 1) % (len(ShipData.player_ship.waypoints) - 1)
		# Signal an update
		ShipData.player_ship.waypoints_updated.emit()
	
func clear_waypoints() -> void:
	# Wipe all waypoints
	ShipData.player_ship.waypoints = []
	# Set the active waypoint to the first one
	ShipData.player_ship.navigation_module.active_waypoint = 0
	# Signal an update
	ShipData.player_ship.waypoints_updated.emit()

func to_hud_string(num: float, prefix: String) -> String:
	num *= 1000 # Convert km to m
	
	var suffix := ""
	
	if abs(num) >= 1e12:
		return prefix + "∞" # return infinity if altitude is too high
	elif abs(num) >= 1e9:
		num /= 1e9
		suffix = "g"
	elif abs(num) >= 1e6:
		num /= 1e6
		suffix = "m"
	elif abs(num) >= 1e3:
		num /= 1e3
		suffix = "k"
	
	return prefix + "%.3f%s" % [num, suffix]
