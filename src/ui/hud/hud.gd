extends Control

var frame_label
var velocity_label
var altitude_label

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get label nodes
	frame_label = get_node("Frame/Label")
	velocity_label = get_node("Velocity/Label")
	altitude_label = get_node("Altitude/Label")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
		# Get and set frame
	frame_label.text = "FRAME " + Conversions.bodies[Conversions.f].name
	
	# Calculate and set altitude
	var r = Conversions.ToFrame(ShipData.player_ship.position,SystemTime.t)
	altitude_label.text = to_hud_string(r.length(), "h")
	
	# Calculate and set velocity
	var v = Conversions.VelToFrame(ShipData.player_ship.velocity,SystemTime.t)
	velocity_label.text = to_hud_string(v.length(), "v")

func to_hud_string(num: float, prefix: String) -> String:
	num *= 1000 # Convert km to m
	
	var suffix := ""
	
	if abs(num) >= 1e12:
		return prefix + "∞" # return infinity if altitude is too high
	elif abs(num) >= 1e9:
		num /= 1e9
		suffix = "g"
	elif abs(num) >= 1e6:
		num /= 1e6
		suffix = "m"
	elif abs(num) >= 1e3:
		num /= 1e3
		suffix = "k"
	
	return prefix + "%.3f%s" % [num, suffix]
