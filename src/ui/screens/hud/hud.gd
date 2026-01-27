extends Control

var frame_label: Label
var velocity_label: Label
var altitude_label: Label

func _ready() -> void:
	# Get label nodes
	frame_label = get_node("Frame/Label")
	velocity_label = get_node("Velocity/Label")
	altitude_label = get_node("Altitude/Label")


func _process(_delta: float) -> void:
	# Get and set frame
	var frame_name: String = Conversions.frame_name.split("/")[-1] # slice out last thing in frame path
	frame_label.text = "FRAME " + frame_name
	
	# Calculate and set altitude
	var r: Vector3 = Conversions.position_inertial_to_body(ShipData.player_ship.position,SimTime.t)
	altitude_label.text = to_hud_string(r.length(), "h")
	
	# Calculate and set velocity
	var v: Vector3 = Conversions.velocity_inertial_to_body(ShipData.player_ship.velocity,SimTime.t)
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
