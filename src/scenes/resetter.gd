extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = -OwnShip.position/1000
	# Setting this root to the negative of the ship position ensures the ship is always at the global origin
	# Should not be necessary (and should have no effect) in a double precision build
	# But the atmosphere plugin needs this for some reason (jitters otherwise)
