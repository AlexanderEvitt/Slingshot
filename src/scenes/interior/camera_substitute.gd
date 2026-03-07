extends Camera3D

@export var player: PlayerCharacter

func _process(_delta: float) -> void:
	# Position the substitute in space relative to the ship
	position = 0.001*(ShipData.player_ship.attitude.inverse()*player.camera.global_position)
	
	# Give the camera an attitude
	global_transform.basis = player.camera.global_transform.basis
