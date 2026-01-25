@tool
class_name LightButton
extends Panel

var light : Panel
var button : Button
@export var label_text : String
@export var button_group : ButtonGroup
@export var on : bool

# Express the signal of its child button as itself
signal toggled

func _ready() -> void:
	light = get_node("Button/Light")
	button = get_node("Button")
	
	# Set the text on the button
	button.text = label_text
	
	# If there's a button_group, set it
	if button_group != null:
		button.button_group = button_group
	
	# send toggled signal to function that changes light color
	button.toggled.connect(_on_toggled)

# Toggling function automatically switches state light
func _on_toggled(new_state: bool) -> void:
	toggled.emit()
	
	# new_state is the new on/off setting of the button (true/false)
	# Set status light
	if new_state:
		# Set the status box to green
		var new_style: StyleBoxFlat = StyleBoxFlat.new()
		new_style.bg_color = Color8(51, 255, 51, 255)
		light.add_theme_stylebox_override("panel",new_style)
	else:
		# Set the status box to red
		var new_style: StyleBoxFlat = StyleBoxFlat.new()
		new_style.bg_color = Color8(128, 0, 0, 255)
		light.add_theme_stylebox_override("panel",new_style)

# Just set state light
func set_state(new_state: bool) -> void:
	on = new_state
	if new_state:
		# Set the status box to green
		var new_style: StyleBoxFlat = StyleBoxFlat.new()
		new_style.bg_color = Color8(51, 255, 51, 255)
		light.add_theme_stylebox_override("panel",new_style)
	else:
		# Set the status box to red
		var new_style: StyleBoxFlat = StyleBoxFlat.new()
		new_style.bg_color = Color8(128, 0, 0, 255)
		light.add_theme_stylebox_override("panel",new_style)
