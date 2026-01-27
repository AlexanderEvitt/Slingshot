extends Node3D

@onready var pointer: Node3D = $Pointer

@export var active_camera: String = "FirstCam"

func _ready() -> void:
	# Set first person camera view
	var active_camera_node: Camera3D = get_node("Pointer/" + active_camera)
	active_camera_node.current = true

func _process(_delta: float) -> void:
	pointer.transform.basis = ShipData.player_ship.attitude
	global_position = ShipData.player_ship.global_position
