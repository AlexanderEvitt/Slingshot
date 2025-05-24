extends Node

var player_ship

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect startup signal
	get_parent().get_node("UI").startup.connect(_on_startup)
	
	# Load ship physics entity
	player_ship = preload("res://ship/entity/ship_entity.tscn").instantiate()

func _on_startup():
	# Add the ship
	add_child(player_ship)
	
	# Tell the ShipData global where its ship node is
	ShipData.player_ship = get_node("PlayerShip")
	ShipData.propagator = get_node("PlayerShip/Propagator")
