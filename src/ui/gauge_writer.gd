extends HBoxContainer

var VGauge
var EGauge

# Called when the node enters the scene tree for the first time.
func _ready():
	VGauge = get_node("ExcessVelocityGauge")
	EGauge = get_node("EccentricityGauge")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	VGauge.value = 0
	
	# Calculate eccentricity
	var e = Conversions.CalcEccentricity(ShipData.player_ship.position,ShipData.player_ship.velocity,SystemTime.t)
	EGauge.value = clamp(pow(e.length(),0.5)/2,0,1)
	EGauge.text = str(snapped(e.length(), 0.01))
	
	# Calculate excess velocity
	var v = Conversions.CalcExcess(ShipData.player_ship.position,ShipData.player_ship.velocity,SystemTime.t)
	VGauge.value = clamp((v/3)+0.5,0,1)
	VGauge.text = str(snapped(v, 0.01))
