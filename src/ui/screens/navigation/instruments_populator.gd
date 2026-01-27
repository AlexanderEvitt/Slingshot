extends VBoxContainer

@onready var accel_gauge: Dial = $MarginContainer/Gauge1
@onready var power_gauge: Dial = $MarginContainer2/Gauge2
@onready var pump_slider: DoubleSlider = $PumpSlider
@onready var temp_slider: DoubleSlider = $TempSlider
@onready var fuel_slider: DoubleSlider = $FuelSlider

func _process(_delta: float) -> void:
	# Set the top two circle gauges based on the acceleration and reactor power
	var acceleration := ShipData.player_ship.acceleration.length()
	accel_gauge.set_fill(acceleration/0.05,String.num(acceleration/0.00981,1) + "G")
	var power := 150*acceleration/0.05
	power_gauge.set_fill(power/150,String.num(power,0) + "GW")
	
	# Set the sliders
	#pump_slider.set_fill_top(ShipData.player_ship.propulsion_module.he_mp)
	#pump_slider.set_fill_bottom(ShipData.player_ship.propulsion_module.de_mp)
	
	#temp_slider.set_fill_top(ShipData.player_ship.propulsion_module.he_mp/2.0)
	#temp_slider.set_fill_bottom(ShipData.player_ship.propulsion_module.de_mp/2.0)
	
	#fuel_slider.set_fill_top(ShipData.player_ship.propulsion_module.he_quant)
	#fuel_slider.set_fill_bottom(ShipData.player_ship.propulsion_module.de_quant)
