extends RigidBody3D

# Apply internal accelerations to rigid body
func _integrate_forces(state):
	# Convert km/s2 -> m/s2
	var experienced_acceleration = -1000*mass*ShipData.player_ship.thrust_acceleration
	# Rotate into interior frame (where x-axis is up)
	experienced_acceleration = experienced_acceleration.rotated(Vector3(0,0,1), PI/2)
	state.apply_central_force(experienced_acceleration)
