extends AudioStreamPlayer

var smoothed_volume_db: float = -80.0
var smoothed_pitch_scale: float = 1.0

func _physics_process(delta: float) -> void:
	# Normalize thrust (0.0 to 1.0)
	var thrust_ratio := clampf(ShipData.player_ship.propulsion_module.power / ShipData.player_ship.propulsion_module.power_limit, 0.0, 1.0)
	# Square root to make values steeper
	thrust_ratio = sqrt(thrust_ratio)

	# Convert to decibels. -60 dB is silent, 0 dB is full volume.
	var volume := lerpf(-20.0, 0.0, thrust_ratio)
	var target_volume_db := clampf(volume, -60.0, 0.0)
	
	# Smooth to eliminate popping
	var speed := 3.0  # smoothing speed; higher = faster response
	smoothed_volume_db = lerpf(smoothed_volume_db, target_volume_db, 1.0 - exp(-speed * delta))
	volume_db = smoothed_volume_db

	# Same for pitch scaling
	var target_pitch_scale := lerpf(0.2, 2.0, thrust_ratio)
	smoothed_pitch_scale = lerpf(smoothed_pitch_scale, target_pitch_scale, 1.0 - exp(-speed * delta))
	pitch_scale = smoothed_pitch_scale
