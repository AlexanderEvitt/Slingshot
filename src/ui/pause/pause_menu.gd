extends Panel

@export var unpause_button : Button
@export var main_menu_button : Button
@export var save_button : Button
@export var quit_button : Button

signal unpause

# Record time rate so you can start time again when unpausing
var last_step := 1

# Record last mouse mode so you can return to it when unpausing
var last_mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	unpause_button.pressed.connect(_unpause_game)
	main_menu_button.pressed.connect(_main_menu)
	save_button.pressed.connect(_save_game)
	quit_button.pressed.connect(_quit_game)

func _unhandled_input(_event: InputEvent) -> void:
	# Pressing escape toggles pause menu
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause_menu()

func _unpause_game():
	# Signal screen_switcher.gd to unpause
	unpause.emit()
	toggle_pause_menu()
	
func _main_menu():
	# Tell ShipData to signal going to main menu
	ShipData.main_menu.emit()

func _quit_game():
	# Quit the game by closing everything
	get_tree().quit()
	
func _save_game():
	# Tell the ShipData singleton to signal everything to save its data
	ShipData.save.emit()

func toggle_pause_menu():
	# Toggle the pause menu
	visible = !visible
	# Stop time while paused
	if visible:
		last_step = SystemTime.i
		SystemTime.i = 0
		# Show mouse
		last_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Start time again when unpausing
	else:
		SystemTime.i = last_step
		# Take mouse back to last mouse mode
		Input.set_mouse_mode(last_mouse_mode)
