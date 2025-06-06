extends Panel

var modes
var keys

var autopilot_status_box
var navigation_status_box

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get modes and keys
	modes = get_tree().get_nodes_in_group("Attitude Modes")
	keys = get_tree().get_nodes_in_group("Autopilot Keys")
	
	# Assign signals to the set_modes bar
	for i in modes:
		i.get_node("Button").button_up.connect(set_modes)
		
	for i in keys:
		if i.get_node("Button").text != "NAV": # nav is already connected as a mode
			i.get_node("Button").button_up.connect(set_modes)
		
	# Get status boxes
	autopilot_status_box = get_node("HBoxContainer2/AutoPanel/VBoxContainer/MarginContainer/Panel")
	navigation_status_box = get_node("HBoxContainer2/NavPanel/VBoxContainer/MarginContainer/Panel")
	
	ShipData.player_ship.auto_disc.connect(autopilot_disconnect)
	ShipData.player_ship.nav_disc.connect(navigation_disconnect)
	
func set_modes():
	## Function that reads in the state of the autopilot panel and sets the
	## appropriate flag in the ship entity
	# Get the current attitude mode
	for i in modes:
		if i.get_node("Button").button_pressed:
			ShipData.player_ship.current_mode = i.get_node("Button").text

	# Set the appropriate flags
	for i in keys:
		match i.get_node("Button").text:
			"INV":
				ShipData.player_ship.inv_flag = i.get_node("Button").button_pressed
			"STAB":
				ShipData.player_ship.stab_flag = i.get_node("Button").button_pressed
			"NAV":
				ShipData.player_ship.nav_flag = i.get_node("Button").button_pressed
			"AUTO":
				ShipData.player_ship.autopilot_flag = i.get_node("Button").button_pressed
				
				
	# Set status boxes
	var new_style = StyleBoxFlat.new()
	if ShipData.player_ship.autopilot_flag:
		# Set the status box to green
		new_style.bg_color = Color8(51, 255, 51, 255)
		autopilot_status_box.add_theme_stylebox_override("panel",new_style)
		autopilot_status_box.get_node("Label").text = "ENGAGED"
	else:
		new_style.bg_color = Color8(128, 0, 0, 255)
		autopilot_status_box.add_theme_stylebox_override("panel",new_style)
		autopilot_status_box.get_node("Label").text = "IDLE"
		
	new_style = StyleBoxFlat.new()
	if ShipData.player_ship.nav_flag:
		# Set the status box to green
		new_style.bg_color = Color8(51, 255, 51, 255)
		navigation_status_box.add_theme_stylebox_override("panel",new_style)
		navigation_status_box.get_node("Label").text = "ENGAGED"
	else:
		new_style.bg_color = Color8(128, 0, 0, 255)
		navigation_status_box.add_theme_stylebox_override("panel",new_style)
		navigation_status_box.get_node("Label").text = "IDLE"

func autopilot_disconnect():
	for i in keys:
		match i.get_node("Button").text:
			"AUTO":
				i.get_node("Button").button_pressed = false
				
	set_modes()
	
	SystemTime.i = 1;
	
func navigation_disconnect():
	for i in keys:
		match i.get_node("Button").text:
			"NAV":
				i.get_node("Button").button_pressed = false
				
	set_modes()
