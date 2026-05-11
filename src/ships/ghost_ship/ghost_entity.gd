extends Node3D

enum View { EXTERNAL, FIRST_PERSON }

@export var default_view: View = View.EXTERNAL

@onready var pointer: Node3D = $Pointer
@onready var _first_cam: Camera3D = $Pointer/FirstCam
@onready var _external_cam: Camera3D = $CameraRig/CameraRotator/Camera3D

var _current_view: View


func _ready() -> void:
	set_view(default_view)


func _process(_delta: float) -> void:
	pointer.transform.basis = ShipData.player_ship.attitude
	global_position = ShipData.player_ship.global_position


# Switch to a specific view.
func set_view(view: View) -> void:
	_current_view = view
	match view:
		View.EXTERNAL:
			_external_cam.current = true
		View.FIRST_PERSON:
			_first_cam.current = true


# Advance to the next view in declaration order.
func cycle_view() -> void:
	set_view((_current_view + 1) % View.size() as View)
