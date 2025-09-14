extends Control

var alerts_list : Control
var caution_annunciator : Button
var warning_annunciator : Button

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect signals from ship entity to functions here
	ShipData.player_ship.auto_disc.connect(auto_disc)
	ShipData.player_ship.nav_disc.connect(nav_disc)
	ShipData.player_ship.nav_next.connect(nav_next)
	ShipData.player_ship.att_clamp.connect(att_clamp)
	ShipData.player_ship.rel_clamp.connect(rel_clamp)
	ShipData.player_ship.collision.connect(collision)
	
	# Get the needed node references
	alerts_list = $"VBoxContainer/MainPanel/ScrollContainer/MarginContainer/AlertsList"
	caution_annunciator = $VBoxContainer/HBoxContainer/CautionAnnunciator
	warning_annunciator = $VBoxContainer/HBoxContainer/WarningAnnunciator
	caution_annunciator.button_up.connect(reset_caution)
	warning_annunciator.button_up.connect(reset_warning)

## Functions that make a label of the required type and trip the alarms

func make_info_label():
	var new_label = Label.new()
	new_label.label_settings = load("res://ui/themes/info_label.tres")
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return new_label

func make_caution_label():
	# Turn on caution annunciator
	caution_annunciator.set_theme_type_variation("Caution")
	
	# Make new caution label
	var new_label = Label.new()
	new_label.label_settings = load("res://ui/themes/caution_label.tres")
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return new_label
	
func make_warning_label():
	# Turn on warning annunciator
	warning_annunciator.set_theme_type_variation("Warning")
	
	# Make new warning label
	var new_label = Label.new()
	new_label.label_settings = load("res://ui/themes/warning_label.tres")
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return new_label
	
## Function to turn off the annunciators

func reset_caution():
	caution_annunciator.set_theme_type_variation("")
	
func reset_warning():
	warning_annunciator.set_theme_type_variation("")

## Function for each type of alert that can be triggered

func auto_disc():
	var new_label = make_caution_label()
	new_label.text = "AUTO_DISC: Autopilot automatically disconnected. Reverted to manual control."
	alerts_list.add_child(new_label)

func nav_disc():
	var new_label = make_caution_label()
	new_label.text = "NAV_DISC: Destination reached, navigation ended."
	alerts_list.add_child(new_label)
	
func nav_next():
	var new_label = make_info_label()
	new_label.text = "NAV_NEXT: Waypoint reached, navigating to next waypoint."
	alerts_list.add_child(new_label)
	
func avi_test():
	var new_label = make_info_label()
	new_label.text = "AVI_TEST: Avionics test completed satisfactorily."
	alerts_list.add_child(new_label)

func att_clamp():
	var new_label = make_caution_label()
	new_label.text = "ATT_CLAMP: Docking clamps attached. Hard dock established."
	alerts_list.add_child(new_label)

func rel_clamp():
	var new_label = make_caution_label()
	new_label.text = "REL_CLAMP: Docking clamps released. Spacecraft free for maneuvering."
	alerts_list.add_child(new_label)
	
func collision():
	var new_label = make_warning_label()
	new_label.text = "COLLISION: Collision detected. Damage sustained."
	alerts_list.add_child(new_label)
