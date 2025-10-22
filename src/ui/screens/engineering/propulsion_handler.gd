extends VBoxContainer

# Gauge reference
@export var power_dial : Node
@export var ve_dial : Node
@export var beta_dial : Node
@export var thrust_dial : Node

# Tank references
@export var he_tank_text : Label
@export var de_tank_text : Label
@export var hyd_tank_text : Label

# Pump slider references
@export var he_pump : Node
@export var de_pump : Node
@export var hyd_pump : Node

# Valve references
@export var he_valve : Node
@export var de_valve : Node
@export var hyd_valve : Node

# Control button references
var butttons
@export var propulsor_button : Button
@export var reactor_button : Button
@export var cryo_button : Button
@export var field_button : Button
@export var limiter_button : Button
@export var scram_inhibit_button : Button

var prop

func _ready():
	# Get a shorthand reference to the propulsion system
	prop = ShipData.player_ship.propulsion_calculator
	
	# Refresh model with control states anytime a button gets pushed
	propulsor_button.toggled.connect(update_model_with_control_states)
	reactor_button.toggled.connect(update_model_with_control_states)
	cryo_button.toggled.connect(update_model_with_control_states)
	field_button.toggled.connect(update_model_with_control_states)
	limiter_button.toggled.connect(update_model_with_control_states)
	scram_inhibit_button.toggled.connect(update_model_with_control_states)

	update_model_with_control_states(false)


func _process(_delta):
	# Assign power to gauge
	var max_power = prop.design_power
	power_dial.set_fill(prop.power/max_power, String.num(prop.power*1e-15,1) + " PW")
	
	# Assign exhaust velocity to gauge
	var c = 299792458 # speed of light, m/s
	var max_ve = 0.1*c
	ve_dial.set_fill(prop.exhaust_velocity/max_ve, String.num(prop.exhaust_velocity/c*100,0) + "%c")

	# Assign beta to beta gauge
	beta_dial.set_fill(prop.beta, String.num(prop.beta,3) + " B")
	
	# Assign throttle to thrust gauge
	thrust_dial.set_fill(prop.throttle/0.05, String.num(prop.throttle*1000.0/9.81,1) + " G")
	
	# Assign valve positions
	if prop.reactor_mass_flow_he > 0.0:
		he_valve.rotation = PI/2.0
	else:
		he_valve.rotation = 0.0
		
	if prop.reactor_mass_flow_de > 0.0:
		de_valve.rotation = PI/2.0
	else:
		de_valve.rotation = 0.0
		
	if prop.propulsor_mass_flow > 0.0:
		hyd_valve.rotation = PI/2.0
	else:
		hyd_valve.rotation = 0.0
	
	# Run pumps
	var max_he_flow = 5.0
	var max_de_flow = 3.5
	var max_hyd_flow = 300.0
	var flow_coefficient = 1473.0
	
	
	var he_pump_speed = prop.reactor_mass_flow_he * flow_coefficient
	he_pump.set_fill_top(prop.reactor_mass_flow_he/max_he_flow)
	he_pump.set_fill_bottom(max_he_flow * flow_coefficient)
	he_pump.set_labels(String.num(3.6*prop.reactor_mass_flow_he,1) + " t/hr", String.num(he_pump_speed,0) + " RPM")
	
	var de_pump_speed = prop.reactor_mass_flow_de * flow_coefficient
	de_pump.set_fill_top(prop.reactor_mass_flow_de/max_de_flow)
	de_pump.set_fill_bottom(max_de_flow * flow_coefficient)
	de_pump.set_labels(String.num(3.6*prop.reactor_mass_flow_de,1) + " t/hr", String.num(de_pump_speed,0) + " RPM")
	
	var hyd_pump_speed = prop.propulsor_mass_flow * flow_coefficient
	hyd_pump.set_fill_top(prop.propulsor_mass_flow/max_hyd_flow)
	hyd_pump.set_fill_bottom(max_hyd_flow * flow_coefficient)
	hyd_pump.set_labels(String.num(3.6*prop.propulsor_mass_flow,1) + " t/hr", String.num(hyd_pump_speed,0) + " RPM")
	
	
	# Assign tank contents
	he_tank_text.text = String.num(prop.he_quant/1000.0, 0) + "t"
	de_tank_text.text = String.num(prop.de_quant/1000.0, 0) + "t"
	hyd_tank_text.text = String.num(prop.hyd_quant/1000.0, 0) + "t"

# Functions for toggling controls
func update_model_with_control_states(_new_state):
	# Send to propulsion module
	prop.propulsor = propulsor_button.button_pressed
	prop.reactor = reactor_button.button_pressed
	prop.cryo = cryo_button.button_pressed
	prop.field = field_button.button_pressed
	prop.thrust_limiter = limiter_button.button_pressed
	prop.scram_inhibit = scram_inhibit_button.button_pressed
