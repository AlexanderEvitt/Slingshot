@tool
extends MeshInstance3D

@export var mount : MeshInstance3D
@export var beam : MeshInstance3D

@export var target = Vector3(1,0,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		pass
	else:
		target = Conversions.FindFrame(SystemTime.t) - ShipData.player_ship.position
		if Input.is_action_pressed("fire"):
			beam.visible = true
		else:
			beam.visible = false
	mount.look_at(target, Vector3(0,1,0))
	mount.rotate_object_local(Vector3(0,1,0), PI/2)
	
	# Clamp rotation to within bounds
	mount.rotation.y = clamp(mount.rotation.y, 0, PI/2)
	mount.rotation.z = clamp(mount.rotation.z, -PI/2, PI/2)
