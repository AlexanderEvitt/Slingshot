extends DirectionalLight3D

# Points sun from direction of Sun towards player

var player: PlayerShip

func _ready() -> void:
	player = get_parent().get_parent().get_parent().get_node("Ships/PlayerShip")

func _process(_delta: float) -> void:
	look_at(player.global_position)
