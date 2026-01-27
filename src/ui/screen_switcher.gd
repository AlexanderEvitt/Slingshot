extends Panel

# Groups
var screens: Array
var buttons: Array
@export var button_group: ButtonGroup

# Specialist panels
@onready var screen_selector_panel: Control = $ScreenSelectorPanel

func _ready() -> void:
	# Get buttons from button_group
	buttons = button_group.get_buttons()
	
	# Get screens (includes screen selector)
	screens = get_children()
	
	# Connect signal to change screen function
	var k := 0
	for b: Button in buttons:
		# Connect signal to change HUD function
		b.pressed.connect(_open_screen.bind(k))
		k += 1
	

func _input(_event: InputEvent) -> void:
	# Pressing page opens screen switch panel
	if Input.is_action_just_pressed("page"):
		# Turn off all the screens (including selector paneL)
		for s: Control in screens:
			s.visible = false
		
		# Turn on the screen selector panel
		screen_selector_panel.visible = true
	
func _open_screen(n: int) -> void:
	# Selecting screen opens just that screen
	var i: = 0
	for child: Control in get_children():
		# If screen is input, show it
		if i == n:
			child.visible = true
		# If not, hide it
		else:
			child.visible = false
		i += 1
