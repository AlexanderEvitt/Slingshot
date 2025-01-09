class_name Drawer
extends Node

func line(pos: Array, color = Color.WHITE_SMOKE, squashed = false):
	if pos == null:
		pos = [Vector3(0,0,0),Vector3(0,0,0)]
		
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for i in pos:
		if squashed:
			i.z = 0
		immediate_mesh.surface_add_vertex(i/1000)
		
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return mesh_instance


## 1 -> Lasts ONLY for current physics frame
## >1 -> Lasts X time duration.
## <1 -> Stays indefinitely
func draw(mesh_instance: MeshInstance3D):
	get_viewport().add_child(mesh_instance)

func undraw(mesh_instance: MeshInstance3D):
	mesh_instance.queue_free()
