extends Node

const UI_SCENE_PATH : String = "res://ui/UIScene.tscn"
const MENU_SCENE_PATH : String = "res://ui/menu/MenuScene.tscn"

@onready var menu = $MenuUI
@onready var loading_bar = menu.loading_bar

var loading := false # enables sending updates to loading bar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect startup signal from menu to command that loads scene
	menu.startup.connect(_on_startup)
	# Connect signal for going back to main menu
	ShipData.main_menu.connect(_go_to_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if loading:
	# Get status of resource loader
		var a = []
		ResourceLoader.load_threaded_get_status(UI_SCENE_PATH,a)
		loading_bar.anchor_right = a[0] # send to progress bar
		
		if a[0] == 1.0:
			initialize()

func _on_startup():
	# Start resource loader
	ResourceLoader.load_threaded_request(UI_SCENE_PATH)
	loading = true

func initialize():
	# Load normal UI and associated subscenes
	var ui = ResourceLoader.load_threaded_get(UI_SCENE_PATH).instantiate()
	add_child(ui)
	
	# Delete menu
	remove_child(menu)
	
	# Start simulation time running
	SystemTime.i = 1;
	
	loading = false

func _go_to_menu():
	# Load and add menu scene
	menu = preload(MENU_SCENE_PATH).instantiate()
	add_child(menu)
	
	# Remove external scene
	remove_child($ShipUI)
	
	# Connect the startup signal again
	menu.startup.connect(_on_startup)
