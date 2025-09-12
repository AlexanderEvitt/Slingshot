extends MarginContainer


@onready var waypoint_row = preload("res://ui/screens/navigation/waypoints/waypoint_row.tscn")
@onready var waypoints_list = $VBoxContainer/MainPanel/ScrollContainer/MarginContainer/Box/WaypointsList
@onready var next_button = $VBoxContainer/MainPanel/ScrollContainer/MarginContainer/Box/NextButton
@onready var clear_button = $VBoxContainer/MainPanel/ScrollContainer/MarginContainer/Box/ClearButton

func _ready():
	# Update waypoints list when ship signals that the waypoints are new
	ShipData.player_ship.waypoints_updated.connect(update_waypoint)
	ShipData.player_ship.nav_next.connect(update_waypoint)
	
	# Connect clear and next buttons
	next_button.pressed.connect(next_waypoint)
	clear_button.pressed.connect(clear_waypoints)

func update_waypoint():
	# Purge all children rows
	for child in waypoints_list.get_children():
		child.queue_free()
	
	# Add each new row
	var i = 0
	for p in ShipData.player_ship.waypoints:
		# Instantiate a new waypoint_row
		var this_waypoint_row = waypoint_row.instantiate()
		
		# Set the from/to flag
		if i == ShipData.player_ship.navigation_calculator.active_waypoint:
			this_waypoint_row.get_node("Flag").text = "FR"
		elif i == ShipData.player_ship.navigation_calculator.active_waypoint + 1:
			this_waypoint_row.get_node("Flag").text = "TO"
		else:
			this_waypoint_row.get_node("Flag").text = "  "
		
		# Update the telemetry of it
		this_waypoint_row.get_node("Number").text = str(i)
		this_waypoint_row.get_node("Frame").text = p["Frame"].split("/")[-1]
		this_waypoint_row.get_node("Distance").text = to_hud_string(p["Position"].length(), "a")
		
		# Add it to the tree
		waypoints_list.add_child(this_waypoint_row)
		i = i + 1

func next_waypoint():
	if len(ShipData.player_ship.waypoints) > 1:
		# Update navigation calculator's active_waypoint value with wrapping
		ShipData.player_ship.navigation_calculator.active_waypoint = (ShipData.player_ship.navigation_calculator.active_waypoint + 1) % (len(ShipData.player_ship.waypoints) - 1)
		# Signal an update
		ShipData.player_ship.waypoints_updated.emit()
	
func clear_waypoints():
	# Wipe all waypoints
	ShipData.player_ship.waypoints = []
	# Set the active waypoint to the first one
	ShipData.player_ship.navigation_calculator.active_waypoint = 0
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
