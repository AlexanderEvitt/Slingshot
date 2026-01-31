extends RigidBody3D

@onready var ship: PlayerShip = ShipData.player_ship

# Apply internal accelerations to rigid body
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Convert km/s2 -> m/s2
	var experienced_acceleration: Vector3 = -1000*mass*ship.thrust_acceleration
	# Rotate into inertial frame
	experienced_acceleration = ship.attitude * experienced_acceleration
	state.apply_central_force(experienced_acceleration)
