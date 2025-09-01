extends VBoxContainer

@onready var accel_gauge = $MarginContainer/Gauge1
@onready var power_gauge = $MarginContainer2/Gauge2
@onready var pump_slider = $PumpSlider
@onready var temp_slider = $TempSlider
@onready var fuel_slider = $FuelSlider

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Set the top two circle gauges based on the acceleration and reactor power
	var acceleration = ShipData.player_ship.propulsion.throttle
	accel_gauge.set_fill(acceleration/0.05,String.num(acceleration/0.00981,1) + "G")
	var power = 150*acceleration/0.05
	power_gauge.set_fill(power/150,String.num(power,0) + "GW")
	
	# Set the sliders
	pump_slider.set_fill_top(ShipData.player_ship.propulsion.he_mp)
	pump_slider.set_fill_bottom(ShipData.player_ship.propulsion.de_mp)
	
	temp_slider.set_fill_top(ShipData.player_ship.propulsion.he_mp/2.0)
	temp_slider.set_fill_bottom(ShipData.player_ship.propulsion.de_mp/2.0)
	
	fuel_slider.set_fill_top(ShipData.player_ship.propulsion.he_quant)
	fuel_slider.set_fill_bottom(ShipData.player_ship.propulsion.de_quant)
