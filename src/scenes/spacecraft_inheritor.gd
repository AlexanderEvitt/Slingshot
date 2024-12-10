extends Node3D



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	transform.basis = OwnShip.attitude
	position = OwnShip.position/1000
	
