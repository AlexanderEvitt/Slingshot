extends GridContainer

var label1: Label
var label2: Label
var label3: Label
var label4: Label
var label5: Label

func _ready() -> void:
	# Get refs to all the labels in the sidebar
	label2 = $"Data2"
	label3 = $"Data3"
	label4 = $"Data4"


func _process(_delta: float) -> void:
	# Calculate and set altitude
	var r := Conversions.position_inertial_to_body(ShipData.player_ship.position,SimTime.t)
	label2.text = str(snapped(r.length(), 1))
	
	# Calculate and set velocity
	var v := Conversions.velocity_inertial_to_body(ShipData.player_ship.velocity,SimTime.t)
	label3.text = str(snapped(v.length(), 0.001))
	
	# Calculate and set eccentricity
	var e := Conversions.calc_eccentricity(ShipData.player_ship.position,ShipData.player_ship.velocity,SimTime.t)
	label4.text = str(snapped(e.length(), 0.001))
