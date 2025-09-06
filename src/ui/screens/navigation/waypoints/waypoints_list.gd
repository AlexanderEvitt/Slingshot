extends MarginContainer


@onready var waypoint_row = preload("res://ui/screens/navigation/waypoints/waypoint_row.tscn")
@onready var waypoints_list = $VBoxContainer/MainPanel/ScrollContainer/MarginContainer/WaypointsList

func _ready():
	ShipData.player_ship.waypoints_updated.connect(update_waypoint)

func update_waypoint():
	# Purge all children rows
	for child in waypoints_list.get_children():
		child.queue_free()
	
	# Add each new row
	var i = 0
	for p in ShipData.player_ship.waypoints:
		# Instantiate a new waypoint_row
		var this_waypoint_row = waypoint_row.instantiate()
		
		# Update the telemetry of it
		this_waypoint_row.get_node("Number").text = str(i)
		this_waypoint_row.get_node("Frame").text = p["Frame"].split("/")[-1]
		this_waypoint_row.get_node("Distance").text = to_hud_string(p["Position"].length(), "a")
		
		# Add it to the tree
		waypoints_list.add_child(this_waypoint_row)
		i = i + 1

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
