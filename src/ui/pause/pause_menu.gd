extends Panel

@export var unpause_button : Button
@export var save_button : Button
@export var quit_button : Button

signal unpause

func _ready() -> void:
	unpause_button.pressed.connect(_unpause_game)
	quit_button.pressed.connect(_quit_game)
	save_button.pressed.connect(_save_game)

func _unpause_game():
	# Signal screen_switcher.gd to unpause
	unpause.emit()

func _quit_game():
	# Quit the game by closing everything
	get_tree().quit()
	
func _save_game():
	# Tell the ShipData singleton to signal everything to save its data
	ShipData.save.emit()
