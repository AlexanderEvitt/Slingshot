extends HBoxContainer

@onready var player = get_parent()

func _ready() -> void:
	# Tell camera to always move with the mouse
	$ExternalUI/SubViewport/PlayerShip/CameraRig.move_always = true

func _process(_delta: float) -> void:
	if !player.focusing and !player.in_transition and Input.is_action_just_pressed("switch_camera"):
		# Flip visibility of popup
		visible = !visible
