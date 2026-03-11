extends Node

# ShipData tracks the reference to the player's ship allowing all the other nodes to reference ship
 # properties easily
# Will in the future also track other ships (NPCs)
@onready var player_ship: PlayerShip # player ship
@onready var sim_root: Node3D # root of external scene
@onready var slot: int = 0 # save game slot
@onready var ship_type: int = 0 # which ship model to use
@onready var sun_angle: Basis

# Game-wide signals
signal save
signal main_menu

# Variables to control floating reference frame, relative to solar system center
var floating_frame_position: Vector3 = Vector3(0,0,0)
var floating_frame_velocity: Vector3 = Vector3(0,0,0)
var floating_frame_time: float = 0.0

func get_floating_frame_origin() -> Vector3:
	# Returns position of floating frame relative to system frame
	# Floating frame origin = position + velocity * (time - frame_time)
	return floating_frame_position + floating_frame_velocity * (SimTime.t - floating_frame_time)
