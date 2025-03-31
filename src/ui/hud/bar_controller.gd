extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Calculate pitch and roll
	var ship_up = OwnShip.attitude * Vector3(0, 1, 0)
	var ship_right = OwnShip.attitude * Vector3(0, 0, 1)
	var ship_forward = OwnShip.attitude * Vector3(1, 0, 0)
	var world_up = (OwnShip.position - Conversions.FindFrame(SystemTime.t)).normalized()
	
	var pitch = PI/2.0 - acos(ship_forward.dot(world_up))
	var roll = PI/2.0 - acos(ship_right.dot(world_up))

	# Check if upright
	var s = ship_up.dot(world_up) # between 0 and 1 if upright
	s = s/abs(s)
	if s < 0:
		ship_up = OwnShip.attitude * Vector3(0, -1, 0)
		roll = PI/2 + acos(ship_right.dot(world_up))
	
	# Move bars by the attitude
	position.y = 384 * (pitch * 180 / (10 * 2 * PI))*cos(roll)  # Adjust Y position based on pitch
	rotation = 2.0*roll
	position.x = -position.y*tan(rotation)
