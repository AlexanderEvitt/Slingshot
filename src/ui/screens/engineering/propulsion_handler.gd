extends VBoxContainer

# Gauge reference
@export var power_dial : Node
@export var ve_dial : Node
@export var beta_dial : Node
@export var thrust_dial : Node

# Tank references
@export var he_tank_text : Label
@export var de_tank_text : Label

var prop

func _ready():
	# Get a shorthand reference to the propulsion system
	prop = ShipData.player_ship.propulsion_calculator



func _process(_delta):
	# Assign power to gauge
	var max_power = 7.0*prop.design_power
	power_dial.set_fill(prop.power/max_power, String.num(prop.power*1e-15,1) + " PW")
	
	# Assign exhaust velocity to gauge
	var max_ve = 1.1*prop.design_ve
	ve_dial.set_fill(prop.exhaust_velocity/max_ve, String.num(prop.exhaust_velocity/prop.design_ve*100,0) + "%")
	
	# Assign tank contents
	he_tank_text.text = String.num(prop.he_quant/1000.0, 0) + "t"
	de_tank_text.text = String.num(prop.de_quant/1000.0, 0) + "t"
	
