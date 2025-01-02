extends GridContainer

var label1
var label2
var label3
var label4

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get refs to all the labels in the sidebar
	label1 = $"Data1"
	label2 = $"Data2"
	label3 = $"Data3"
	label4 = $"Data4"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Get and set frame
	if Input.is_action_just_released("next_frame"):
		label1.text = Conversions.bodies[Conversions.f].name
	
	# Calculate and set altitude
	var r = Conversions.ToFrame(OwnShip.position,SystemTime.t)
	label2.text = str(snapped(r.length(), 1))
	
	# Calculate and set velocity
	var v = Conversions.VelToFrame(OwnShip.velocity,SystemTime.t)
	label3.text = str(snapped(v.length(), 0.001))
	
	# Calculate and set eccentricity
	var e = Conversions.CalcEccentricity(OwnShip.position,OwnShip.velocity,SystemTime.t)
	label4.text = str(snapped(e.length(), 0.001))
