extends Panel

signal startup

@export var loading_bar : Control
@export var start_button : LightButton
@export var startup_panel : Panel
@export var slot_button_group : ButtonGroup

var slot: int # slot to load data from

func _ready() -> void:
	start_button.toggled.connect(_on_startup)
	
func _on_startup() -> void:
	# Emit the startup signal when the start button is toggled
	startup.emit()
	# Hide the startup panel
	startup_panel.visible = false
	
	# Set save game slot
	slot = slot_button_group.get_pressed_button().id
	ShipData.slot = slot
