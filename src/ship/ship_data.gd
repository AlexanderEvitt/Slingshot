extends Node

# ShipData tracks the reference to the player's ship allowing all the other nodes to reference ship
 # properties easily
# Will in the future also track other ships (NPCs)
@onready var player_ship = self # player ship
@onready var sim_root = self # root of external scene
@onready var slot = 0 # save game slot

# Game-wide signals
signal save
signal main_menu
