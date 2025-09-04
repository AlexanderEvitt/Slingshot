class_name Drawer
extends Node3D

var scaledown = 1

func line(pos: Array, color = Color.WHITE_SMOKE, squashed = false):
	# If there's no positions, make up bogus zero positions
	if pos == null:
		pos = [Vector3(0,0,0),Vector3(0,0,0)]
		
	# Create new mesh and material
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	# Assign
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Start drawing line along positions
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for i in pos:
		if squashed:
			i.z = 0
		immediate_mesh.surface_add_vertex(i/scaledown)
		
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	return mesh_instance


## 1 -> Lasts ONLY for current physics frame
## >1 -> Lasts X time duration.
## <1 -> Stays indefinitely
func draw(parent: Node, mesh_instance: MeshInstance3D):
	parent.add_child(mesh_instance)

func undraw(mesh_instance: MeshInstance3D):
	mesh_instance.queue_free()
