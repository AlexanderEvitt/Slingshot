extends HBoxContainer

@onready var player: PlayerCharacter = get_parent()

func _ready() -> void:
	# Tell camera to always move with the mouse
	@warning_ignore("unsafe_property_access")
	$ExternalUI/SubViewport/PlayerShip/CameraRig.move_always = true
