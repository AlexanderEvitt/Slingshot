extends Node3D

@onready var player: PlayerCharacter = $Player

func _ready() -> void:
	# Load and child that is the interior model corresponding to the right ship
	if ShipData.ship_type == 0:
		var interior_scene: PackedScene = load("res://ships/juniper/interior/interior_model.tscn")
		add_child(interior_scene.instantiate())
	elif ShipData.ship_type == 1:
		var interior_scene: PackedScene = load("res://ships/locust/interior/interior_model.tscn")
		add_child(interior_scene.instantiate())
		
	# Get all the viewpoint nodes in the model and give them to the player
	player.viewpoints = get_tree().get_nodes_in_group("Viewpoints")

func _process(_delta: float) -> void:
	# Rotate entire interior to align with simulated ship attitude
	transform.basis = ShipData.player_ship.attitude
	rotate_object_local(Vector3(0,0,1), -PI/2)
