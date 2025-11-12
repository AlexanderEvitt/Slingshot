extends AudioStreamPlayer

var smoothed_volume_db: float = -80.0

func _process(delta):
	# Normalize thrust (0.0 to 1.0)
	var thrust_ratio = clamp(ShipData.player_ship.propulsion_calculator.power / ShipData.player_ship.propulsion_calculator.power_limit, 0.0, 1.0)
	# Square root to make values steeper
	thrust_ratio = sqrt(thrust_ratio)

	# Convert to decibels. -60 dB is silent, 0 dB is full volume.
	var volume = lerp(-60.0, 0.0, thrust_ratio)
	var target_volume_db = clamp(volume, -60.0, 0.0)
	
	# Smooth to eliminate popping
	var speed = 30.0  # smoothing speed; higher = faster response
	smoothed_volume_db = lerp(smoothed_volume_db, target_volume_db, 1.0 - exp(-speed * delta))
	volume_db = smoothed_volume_db

	# Optional: add a bit of pitch scaling for realism
	pitch_scale = lerp(0.8, 1.2, thrust_ratio)
