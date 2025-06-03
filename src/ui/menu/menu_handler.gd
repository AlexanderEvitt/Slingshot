extends Node

var start_button
var progress_bar
var done_light
const UI_SCENE_PATH : String = "res://ui/UIScene.tscn"

signal startup

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start resource loader
	ResourceLoader.load_threaded_request(UI_SCENE_PATH)
	# Connect start button signal
	start_button = get_node("MenuUI/StartupPanel/HBoxContainer/Centerfold/MarginContainer/VBoxContainer/CenterPanel/PanelsHolder/NewSimConfig/NewSimConfig/HBoxContainer2/StartPanel/VBoxContainer/ButtonContainer/MarginContainer/LightButtonPanel/Button")
	progress_bar = get_node("MenuUI/StartupPanel/HBoxContainer/Centerfold/MarginContainer/VBoxContainer/CenterPanel/PanelsHolder/NewSimConfig/LoadingBack/TextureRect")
	done_light = get_node("MenuUI/StartupPanel/HBoxContainer/Centerfold/MarginContainer/VBoxContainer/CenterPanel/PanelsHolder/NewSimConfig/NewSimConfig/HBoxContainer2/StartPanel/VBoxContainer/MarginContainer/Panel")
	start_button.button_up.connect(_on_startup)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Get status of resource loader
	var a = []
	ResourceLoader.load_threaded_get_status(UI_SCENE_PATH,a)
	progress_bar.anchor_right = a[0] # send to progress bar
	if a[0] == 1: # send to done light
		done_light.toggled = true
	

func _on_startup():
	# Emit signal (for creating player ship)
	startup.emit()
	
	# Load normal UI and associated subscenes
	var ui = ResourceLoader.load_threaded_get(UI_SCENE_PATH).instantiate()
	add_child(ui)
	
	# Delete menu
	self.remove_child(get_node("MenuUI"))
	
	# Start simulation time running
	SystemTime.i = 1;
