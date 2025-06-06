@tool
extends Panel

var light
var button
@export var label_text : String
@export var button_group : ButtonGroup
@export var on : bool
var previously_on : bool

func _ready():
	light = get_node("Button/Light")
	button = get_node("Button")
	
	# Set the text on the button
	button.text = label_text
	
	# If there's a button_group, set it
	if button_group != null:
		button.button_group = button_group
	
	# send toggled signal to function that changes light color
	button.toggled.connect(_on_toggled)

func _on_toggled(new_state):
	# new_state is the new on/off setting of the button
	# Set status light
	if new_state:
		# Set the status box to green
		var new_style = StyleBoxFlat.new()
		new_style.bg_color = Color8(51, 255, 51, 255)
		light.add_theme_stylebox_override("panel",new_style)
	else:
		# Set the status box to red
		var new_style = StyleBoxFlat.new()
		new_style.bg_color = Color8(128, 0, 0, 255)
		light.add_theme_stylebox_override("panel",new_style)
