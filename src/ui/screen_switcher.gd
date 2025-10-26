extends Panel

# Groups
var screens
var buttons
@export var button_group: ButtonGroup

# Specialist panels
@onready var screen_selector_panel := $ScreenSelectorPanel
@onready var pause_menu := $PauseMenu

# Record time rate so you can start time again when unpausing
var last_step := 1

func _ready():
	# Get buttons from button_group
	buttons = button_group.get_buttons()
	
	# Get screens (includes screen selector and pause)
	screens = get_children()
	
	# Connect signal to change screen function
	var k = 0
	for b in buttons:
		# Connect signal to change HUD function
		b.pressed.connect(_open_screen.bind(k))
		k += 1
		
	# Connect unpause signal from pause menu's unpause button
	pause_menu.unpause.connect(toggle_pause_menu)
	

func _input(_event: InputEvent) -> void:
	# Pressing page opens screen switch panel
	if Input.is_action_just_pressed("page"):
		# Turn off all the screens (including selector paneL)
		for s in screens:
			s.visible = false
		
		# Turn on the screen selector panel
		screen_selector_panel.visible = true
		
	# Pressing escape toggles pause menu
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause_menu()
	
func _open_screen(n):
	# Selecting screen opens just that screen
	var i = 0
	for child in get_children():
		# If screen is input, show it
		if i == n:
			child.visible = true
		# If not, hide it
		else:
			child.visible = false
		i += 1

func toggle_pause_menu():
	# Toggle the pause menu
	pause_menu.visible = !pause_menu.visible
	# Stop time while paused
	if pause_menu.visible:
		last_step = SystemTime.i
		SystemTime.i = 0
	# Start time again when unpausing
	else:
		SystemTime.i = last_step
