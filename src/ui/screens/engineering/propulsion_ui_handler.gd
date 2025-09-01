extends HBoxContainer

# Paths of widgets
@export var he_tank : Node
@export var de_tank : Node
@export var he_pump : Node
@export var de_pump : Node
@export var thrust_bar : Node
@export var he_pump_spinner : Node
@export var de_pump_spinner : Node
@export var tca : Node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Set the fill line of the tanks
	he_tank.set_fill(ShipData.player_ship.propulsion.he_quant)
	de_tank.set_fill(ShipData.player_ship.propulsion.de_quant)
	
	# Set the pump speed circle gauges
	he_pump.set_fill(ShipData.player_ship.propulsion.he_mp,String.num(ShipData.player_ship.propulsion.he_mp,2))
	de_pump.set_fill(ShipData.player_ship.propulsion.de_mp,String.num(ShipData.player_ship.propulsion.de_mp,2))
	
	var power = ShipData.player_ship.propulsion.throttle/0.05
	
	thrust_bar.set_fill(power)
	tca.amount_ratio = power
	he_pump_spinner.rotation = he_pump_spinner.rotation + ShipData.player_ship.propulsion.he_mp
	de_pump_spinner.rotation = de_pump_spinner.rotation + ShipData.player_ship.propulsion.de_mp
