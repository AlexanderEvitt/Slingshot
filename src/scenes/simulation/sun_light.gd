extends DirectionalLight3D

# Points sun from direction of Sun towards player

@onready var player: PlayerShip = ShipData.player_ship

func _process(_delta: float) -> void:
	look_at(player.global_position)
	ShipData.sun_angle = global_transform.basis
