extends Node

# ShipData tracks the reference to the player's ship allowing all the other nodes to reference ship
 # properties easily
# Will in the future also track other ships (NPCs)
@onready var player_ship = self # player ship
@onready var physics_root = self # root of external scene
