extends Node

const UI_SCENE_PATH : String = "res://ui/UIScene.tscn"

@onready var menu = $MenuUI
@onready var loading_bar = menu.loading_bar

var loading := false # enables sending updates to loading bar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect startup signal from menu to command that loads scene
	menu.startup.connect(_on_startup)

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
	
	# Tell ShipData which slot the save game
	ShipData.slot = menu.slot

func initialize():
	# Load normal UI and associated subscenes
	var ui = ResourceLoader.load_threaded_get(UI_SCENE_PATH).instantiate()
	add_child(ui)
	
	# Delete menu
	remove_child(menu)
	
	# Start simulation time running
	SystemTime.i = 1;
	
	loading = false
