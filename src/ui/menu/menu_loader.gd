extends Node

const INTERIOR_SCENE_PATH : String = "res://scenes/interior/InteriorScene.tscn"
const PHYSICS_SCENE_PATH : String = "res://scenes/external/ExternalScene.tscn"
const MENU_SCENE_PATH : String = "res://ui/menu/MenuScene.tscn"

@onready var menu = $MenuUI
@onready var loading_bar = menu.loading_bar

var loading := false # enables sending updates to loading bar

func _ready() -> void:
	# Connect startup signal from menu to command that loads scene
	menu.startup.connect(_on_startup)
	# Connect signal for going back to main menu
	ShipData.main_menu.connect(_go_to_menu)

func _process(_delta: float) -> void:
	if loading:
	# Get status of resource loader
		var a = []
		var b = []
		ResourceLoader.load_threaded_get_status(INTERIOR_SCENE_PATH,a)
		ResourceLoader.load_threaded_get_status(PHYSICS_SCENE_PATH,b)
		loading_bar.anchor_right = (a[0] + b[0])/2.0 # send to progress bar
		
		if (a[0] + b[0])/2.0 == 1.0:
			initialize()

func _on_startup():
	# Start resource loader for both interior and physics
	ResourceLoader.load_threaded_request(INTERIOR_SCENE_PATH)
	ResourceLoader.load_threaded_request(PHYSICS_SCENE_PATH)
	loading = true

func initialize():
	# Load scenes, physics scene first (so ship exists before UI calls)
	# Finish loading physics scene
	var physics = ResourceLoader.load_threaded_get(PHYSICS_SCENE_PATH).instantiate()
	$SimulationHolder.add_child(physics)
	
	# Finish loading interior scene
	var interior = ResourceLoader.load_threaded_get(INTERIOR_SCENE_PATH).instantiate()
	add_child(interior)
	
	# Delete menu
	remove_child(menu)
	
	# Start simulation time running
	SystemTime.i = 1;
	
	loading = false

func _go_to_menu():
	# Load and add menu scene
	menu = preload(MENU_SCENE_PATH).instantiate()
	add_child(menu)
	
	# Remove interior and physics
	remove_child($interior)
	remove_child($SimulationHolder/SimRoot)
	
	# Connect the startup signal again
	menu.startup.connect(_on_startup)
