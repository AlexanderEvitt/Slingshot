extends AudioStreamPlayer

@export var alarm_type = "caution"
var current_state = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var new_state = ShipData.player_ship.avionics[alarm_type]
	# Compare new state of alarm to previous state
	# If different, update playing parameter
	if current_state != new_state:
		playing = new_state
	
	# Update current state
	current_state = new_state
