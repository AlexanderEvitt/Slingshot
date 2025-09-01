extends DirectionalLight3D

var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent().get_parent().get_parent().get_node("Ships/PlayerShip")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	look_at(player.global_position)
