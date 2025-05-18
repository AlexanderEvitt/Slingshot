extends Panel

var screen_selector_panel
var screens
@export var button_group: ButtonGroup
var buttons

func _ready():
	# Get screen selector panel
	screen_selector_panel = get_node("ScreenSelectorPanel")
	
	# Get buttons from button_group
	buttons = button_group.get_buttons()
	
	# Get screens (includes screen selector)
	screens = get_children()
	
	# Connect signal to change screen function
	var k = 0
	for b in buttons:
		# Connect signal to change HUD function
		b.pressed.connect(_open_screen.bind(k))
		k += 1
	

func _input(_event: InputEvent) -> void:
	## Pressing ESC opens screen switch panel
	if Input.is_action_just_pressed("ui_cancel"):
		# Turn off all the screens (including selector paneL)
		for s in screens:
			s.visible = false
		
		# Turn on the screen selector panel
		screen_selector_panel.visible = true
	
func _open_screen(n):
	## Selecting screen opens just that screen
	var i = 0
	for child in get_children():
		# If screen is input, show it
		if i == n:
			child.visible = true
		# If not, hide it
		else:
			child.visible = false
		i += 1
