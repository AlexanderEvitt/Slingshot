extends Camera3D

@export var player: PlayerCharacter
@export var camera: Camera3D

func _process(_delta: float) -> void:
	# Position the substitute in space relative to the ship
	position = -0.001*(camera.position + player.position)
	
	# Give the camera an attitude
	global_transform.basis = camera.global_transform.basis
