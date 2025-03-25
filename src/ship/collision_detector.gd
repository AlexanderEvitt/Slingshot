extends RigidBody3D

var impulse = Vector3(0,0,0)

func _process(_delta):
	transform.basis = OwnShip.attitude

func _integrate_forces(state):
	impulse = Vector3(0,0,0)
	for i in range(state.get_contact_count()):
		var _contact_point = state.get_contact_local_position(i)  # Contact position
		var contact_normal = state.get_contact_local_normal(i)  # Contact normal
		var _colliding_body = state.get_contact_collider(i)  # Other body
		var colliding_vel = state.get_contact_collider_velocity_at_position(i) # velocity
		
		var dv = colliding_vel - get_parent().velocity
		impulse += contact_normal*dv
