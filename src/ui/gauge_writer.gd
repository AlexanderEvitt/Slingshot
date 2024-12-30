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
	var e = Conversions.CalcEccentricity(OwnShip.position,OwnShip.velocity,SystemTime.t)
	EGauge.value = clamp(pow(e.length(),0.5),0,1)
