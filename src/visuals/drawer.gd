class_name Drawer
extends Node

func line(pos: Array, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for i in pos:
		immediate_mesh.surface_add_vertex(i/1000)
		
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, persist_ms)


## 1 -> Lasts ONLY for current physics frame
## >1 -> Lasts X time duration.
## <1 -> Stays indefinitely
func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	get_viewport().add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
