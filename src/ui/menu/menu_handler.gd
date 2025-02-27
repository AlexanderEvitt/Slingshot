extends Node

var start_button
const UI_SCENE_PATH : String = "res://ui/UIScene.tscn"

signal startup

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start resource loader
	ResourceLoader.load_threaded_request(UI_SCENE_PATH)
	# Connect start button signal
	start_button = get_node("MenuUI/MarginContainer/VBoxContainer/MainPanel/Button")
	start_button.pressed.connect(_on_startup)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Get status of resource loader
	var a = []
	ResourceLoader.load_threaded_get_status(UI_SCENE_PATH,a)
	var progress = round(100*a[0])
	start_button.text = "START AVIONICS - " + str(progress) + "% LOADED"

func _on_startup():
	# Emit signal (for creating player ship)
	startup.emit()
	
	# Load UI and associated subscenes
	var ui = ResourceLoader.load_threaded_get(UI_SCENE_PATH).instantiate()
	add_child(ui)
	
	# Delete menu
	self.remove_child(get_node("MenuUI"))
	
	# Start simulation time running
	SystemTime.i = 1;
