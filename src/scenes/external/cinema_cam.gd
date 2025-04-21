extends Camera3D

var offset = Vector3(1,0,0)
var thrust_offset = Vector3(0,0,0)
var offset_vel = Vector3(0,0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if current:
		look_at_from_position(offset + thrust_offset, Vector3(0,0,0), Vector3(0,0,1))
		position = OwnShip.position + offset + thrust_offset
		
		var dt = SystemTime.step*0.03333
		offset_vel += OwnShip.attitude*(OwnShip.thrust - OwnShip.throttle*Vector3(1,0,0))*dt
		thrust_offset -= offset_vel*dt
		
		if Input.is_action_just_pressed("view"):
			offset = get_offset(0.5)
			thrust_offset = Vector3(0,0,0)
			offset_vel = Vector3(0,0,0)
	

func get_offset(d):
	var forward = OwnShip.attitude*Vector3(1,0,0)
	var right = OwnShip.attitude*Vector3(0,0,1)
	var up = OwnShip.attitude*Vector3(0,1,0)
	return d*(2*(randf()-0.5))*forward + d*(2*(randf()-0.5))*right + d*(2*(randf()-0.5))*up
