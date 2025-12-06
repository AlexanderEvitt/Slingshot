extends Panel


var autopilot_status_box
var navigation_status_box

# Modes are autopilot pointing directions
@export var hdg_mode : Control
@export var crs_mode : Control
@export var trg_mode : Control
@export var nrm_mode : Control
# Keys are on/off autopilot modes (e.g. AUTO or NAV)
@export var auto_key : Control
@export var nav_key : Control
@export var inv_key : Control
@export var stab_key : Control

# State of autopilot is maintained by ship_entity
# Pressing a key button inverts the state of that avionic
# Pressing a mode button sets the "attitude_mode" parameter
# Keys get their status directly from the ship_entity
# Modes get their status from "attitude_mode" 

func _ready():
	# Connect the modes
	hdg_mode.toggled.connect(_set_mode.bind("HDG"))
	crs_mode.toggled.connect(_set_mode.bind("CRS"))
	trg_mode.toggled.connect(_set_mode.bind("TRG"))
	nrm_mode.toggled.connect(_set_mode.bind("NRM"))
	nav_key.toggled.connect(_set_mode.bind("NAV")) # both a mode and a key
	
	# Connect the keys
	auto_key.toggled.connect(_toggle_key.bind("autopilot"))
	nav_key.toggled.connect(_toggle_key.bind("navigation"))
	inv_key.toggled.connect(_toggle_key.bind("attitude_inv"))
	stab_key.toggled.connect(_toggle_key.bind("attitude_stab"))

func _process(_delta: float) -> void:
	# Set the status of each key to its state
	auto_key.set_state(ShipData.player_ship.avionics["autopilot"])
	nav_key.set_state(ShipData.player_ship.avionics["navigation"])
	inv_key.set_state(ShipData.player_ship.avionics["attitude_inv"])
	stab_key.set_state(ShipData.player_ship.avionics["attitude_stab"])
	
	# Set the mode to on if it's the current mode
	for m in [hdg_mode, crs_mode, trg_mode, nrm_mode]:
		if ShipData.player_ship.avionics["attitude_mode"] == m.label_text:
			m.set_state(true)
		else:
			m.set_state(false)

# Toggles the key of a specified variable
func _toggle_key(variable):
	ShipData.player_ship.avionics[variable] = !ShipData.player_ship.avionics[variable]

# Sets the pressed mode in the avionics
func _set_mode(mode):
	# If mode isn't the current one, make it the current one
	if mode != ShipData.player_ship.avionics["attitude_mode"]:
		ShipData.player_ship.avionics["attitude_mode"] = mode
	# Otherwise, set the mode to nothing
	else:
		ShipData.player_ship.avionics["attitude_mode"] = ""
