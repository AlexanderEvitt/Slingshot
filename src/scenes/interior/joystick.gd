extends MeshInstance3D

# Wiggles the joystick with the applied torque
func _process(_delta):
	var torque = ShipData.player_ship.attitude_calculator.commanded_torque
	
	var s = 1.5
	rotation = s*Vector3(torque.z,torque.y,-torque.x)
