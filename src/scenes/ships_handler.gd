extends Node

var player_ship

func _ready() -> void:

	# Tell the ShipData global how to reference the planets
	ShipData.sim_root = get_parent()
	Conversions.sim_root = get_parent()
	
	# Load ship physics entity
	player_ship = preload("res://ship/entity/ship_entity.tscn").instantiate()

	add_child(player_ship)
	
	# If save game exists, load the data into the ship
	
	
	# Tell the ShipData global where its ship node is
	ShipData.player_ship = get_node("PlayerShip")
