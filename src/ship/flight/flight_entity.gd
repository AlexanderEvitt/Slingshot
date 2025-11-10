extends Node3D

@onready var pointer = $Pointer

@export var active_camera := "FirstCam"

func _ready() -> void:
	get_node("Pointer/" + active_camera).current = true

func _process(_delta):
	pointer.transform.basis = ShipData.player_ship.attitude
	global_position = ShipData.player_ship.global_position
