extends Panel

signal startup

@export var loading_bar : Node
@export var start_button : Node
@export var startup_panel : Node
@export var slot_button_group : ButtonGroup

var slot # slot to load data from

func _ready():
	start_button.toggled.connect(_on_startup)
	
func _on_startup():
	# Emit the startup signal when the start button is toggled
	startup.emit()
	# Hide the startup panel
	startup_panel.visible = false
	
	# Set save game slot
	slot = slot_button_group.get_pressed_button().id
	ShipData.slot = slot
