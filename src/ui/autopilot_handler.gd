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
		i.pressed.connect(set_modes)
		
	for i in keys:
		if i.text != "NAV": # nav is already connected as a mdoe
			i.pressed.connect(set_modes)
		
	# Get status boxes
	autopilot_status_box = get_node("HBoxContainer2/AutoPanel/VBoxContainer/MarginContainer/Panel")
	navigation_status_box = get_node("HBoxContainer2/NavPanel/VBoxContainer/MarginContainer/Panel")
	
func set_modes():
	## Function that reads in the state of the autopilot panel
	# Get the current attitude mode
	for i in modes:
		if i.button_pressed:
			OwnShip.ship.current_mode = i.text
			
	# Set the appropriate flags
	for i in keys:
		match i.text:
			"INV":
				OwnShip.ship.inv_flag = i.button_pressed
			"STAB":
				OwnShip.ship.stab_flag = i.button_pressed
			"NAV":
				OwnShip.ship.nav_flag = i.button_pressed
			"AUTO":
				OwnShip.ship.autopilot_flag = i.button_pressed
				
				
	# Set status boxes
	var new_style = StyleBoxFlat.new()
	if OwnShip.ship.autopilot_flag:
		# Set the status box to green
		new_style.bg_color = Color8(51, 255, 51, 255)
		autopilot_status_box.add_theme_stylebox_override("panel",new_style)
		autopilot_status_box.get_node("Label").text = "ENGAGED"
	else:
		new_style.bg_color = Color8(128, 0, 0, 255)
		autopilot_status_box.add_theme_stylebox_override("panel",new_style)
		autopilot_status_box.get_node("Label").text = "IDLE"
		
	new_style = StyleBoxFlat.new()
	if OwnShip.ship.nav_flag:
		# Set the status box to green
		new_style.bg_color = Color8(51, 255, 51, 255)
		navigation_status_box.add_theme_stylebox_override("panel",new_style)
		navigation_status_box.get_node("Label").text = "ENGAGED"
	else:
		new_style.bg_color = Color8(128, 0, 0, 255)
		navigation_status_box.add_theme_stylebox_override("panel",new_style)
		navigation_status_box.get_node("Label").text = "IDLE"
