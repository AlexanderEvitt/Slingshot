extends Node3D

func _process(_delta):
	position = -ShipData.player_ship.position
	# Setting this root to the negative of the ship position ensures the cam is always near the global origin
	# Should not be necessary (and should have no effect) in a double precision build
	# But the atmosphere plugin needs this for some reason (jitters otherwise)
	# Updated to ship position from camera position
	# Because current external scene setup has cameras under different viewports from objects
