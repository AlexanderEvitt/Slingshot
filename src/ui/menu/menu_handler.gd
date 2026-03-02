class_name Menu
extends Panel

signal startup

@export var loading_bar : Control
@export var start_button : LightButton
@export var startup_panel : Panel
@export var slot_button_group : ButtonGroup
@export var ship_select : OptionButton

var slot: int # slot to load data from

func _ready() -> void:
	start_button.toggled.connect(_on_startup)
	
func _on_startup() -> void:
	# Emit the startup signal when the start button is toggled
	startup.emit()
	# Hide the startup panel
	startup_panel.visible = false
	
	# Set save game slot
	var save_slot_button := slot_button_group.get_pressed_button() as SaveSlotButton
	slot = save_slot_button.id
	ShipData.slot = slot
	
	# Set ship type
	ShipData.ship_type = ship_select.selected
