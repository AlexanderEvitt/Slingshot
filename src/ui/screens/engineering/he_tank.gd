extends TankWidget

func _process(_delta):
	set_fill(ShipData.player_ship.propulsion.he_quant)
