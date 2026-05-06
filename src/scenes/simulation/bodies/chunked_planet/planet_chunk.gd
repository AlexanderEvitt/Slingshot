@tool
class_name PlanetChunk
extends Node3D

@export var surface_material: Material

@export var resolution: int = 64:
	set(v):
		resolution = v
		if Engine.is_editor_hint() and mesh_instance:
			build_mesh(face_normal, radius)

@export var radius: float = 100.0:
	set(v):
		radius = v
		if Engine.is_editor_hint() and mesh_instance:
			build_mesh(face_normal, radius)

@export var displacement_scale: float = 5.0:
	set(v):
		displacement_scale = v
		if Engine.is_editor_hint() and mesh_instance:
			build_mesh(face_normal, radius)

@export var face_normal: Vector3 = Vector3.UP:
	set(v):
		face_normal = v
		if Engine.is_editor_hint() and mesh_instance:
			build_mesh(face_normal, radius)

@export var local_center: Vector2 = Vector2.ZERO
@export var half_size: float = 1.0
@export var skirt_depth: float = 2.0

var mesh_instance: MeshInstance3D
var sampler: HeightmapSampler

func _ready() -> void:
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
		mesh_instance.owner = owner
	build_mesh(face_normal, radius)

func build_mesh(f_normal: Vector3, r: float) -> void:
	if mesh_instance == null:
		return

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var axis_a: Vector3 = Vector3(f_normal.y, f_normal.z, f_normal.x)
	var axis_b: Vector3 = f_normal.cross(axis_a)

	for y in range(resolution):
		for x in range(resolution):
			var corners: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for coord in [[x, y], [x+1, y], [x, y+1], [x+1, y+1]]:
				var cube_point := _local(coord[0], coord[1], f_normal, axis_a, axis_b)
				var unit_dir := cube_point.normalized()
				uvs.append(_dir_to_uv(unit_dir))
				corners.append(_displaced_vertex_from_dir(unit_dir, r))

			surface.set_uv(uvs[0]); surface.add_vertex(corners[0])
			surface.set_uv(uvs[2]); surface.add_vertex(corners[2])
			surface.set_uv(uvs[1]); surface.add_vertex(corners[1])
			surface.set_uv(uvs[1]); surface.add_vertex(corners[1])
			surface.set_uv(uvs[2]); surface.add_vertex(corners[2])
			surface.set_uv(uvs[3]); surface.add_vertex(corners[3])

	surface.generate_normals()
	_add_skirts(surface, f_normal, axis_a, axis_b, r)
	mesh_instance.mesh = surface.commit()
	
	if surface_material != null:
		mesh_instance.material_override = surface_material

# Now just a convenience wrapper used by _add_skirts
func _displaced_vertex(x: int, y: int, face: Vector3, a: Vector3, b: Vector3, r: float) -> Vector3:
	var cube_point := _local(x, y, face, a, b)
	return _displaced_vertex_from_dir(cube_point.normalized(), r)

# Core displacement logic, used by both build_mesh and _displaced_vertex
func _displaced_vertex_from_dir(unit_dir: Vector3, r: float) -> Vector3:
	var height := 0.0
	if sampler != null:
		height = sampler.sample(unit_dir)
	return unit_dir * (r + height * displacement_scale)

# Converts a point on the unit sphere to equirectangular UV
func _dir_to_uv(unit_dir: Vector3) -> Vector2:
	var lon := atan2(unit_dir.x, unit_dir.z)
	var lat := asin(clamp(unit_dir.y, -1.0, 1.0))
	var u := (lon / (2.0 * PI)) + 0.5
	var v := 1.0 - ((lat / PI) + 0.5)  # flip V
	return Vector2(u, v)

func _local(x: int, y: int, face: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var fx := (float(x) / float(resolution)) * 2.0 - 1.0
	var fy := (float(y) / float(resolution)) * 2.0 - 1.0
	# Scale to this chunk's region
	fx = local_center.x + fx * half_size
	fy = local_center.y + fy * half_size
	return face + a * fx + b * fy

func _cube_to_sphere(cube_point: Vector3, r: float) -> Vector3:
	return cube_point.normalized() * r

func _add_skirts(surface: SurfaceTool, f_normal: Vector3, a: Vector3, b: Vector3, r: float) -> void:
	# For each of the 4 edges, build a row of quads that hang downward
	# Edge order: bottom (y=0), top (y=res), left (x=0), right (x=res)
	var edges := [
		{"fixed": "y", "fixed_val": 0,          "iter": "x", "reverse": false},
		{"fixed": "y", "fixed_val": resolution,  "iter": "x", "reverse": true},
		{"fixed": "x", "fixed_val": 0,           "iter": "y", "reverse": true},
		{"fixed": "x", "fixed_val": resolution,  "iter": "y", "reverse": false},
	]

	for edge in edges:
		for i in range(resolution):
			var i0 := i
			var i1 := i + 1

			# Two vertices on the surface edge
			var v0: Vector3
			var v1: Vector3
			if edge["iter"] == "x":
				var yv: int = edge["fixed_val"]
				v0 = _displaced_vertex(i0, yv, f_normal, a, b, r)
				v1 = _displaced_vertex(i1, yv, f_normal, a, b, r)
			else:
				var xv: int = edge["fixed_val"]
				v0 = _displaced_vertex(xv, i0, f_normal, a, b, r)
				v1 = _displaced_vertex(xv, i1, f_normal, a, b, r)

			# Skirt vertices pushed toward planet center
			var s0 := v0 - v0.normalized() * skirt_depth
			var s1 := v1 - v1.normalized() * skirt_depth

			# Winding depends on which edge to keep normals outward
			if edge["reverse"]:
				surface.add_vertex(v0);  surface.add_vertex(s0);  surface.add_vertex(v1)
				surface.add_vertex(v1);  surface.add_vertex(s0);  surface.add_vertex(s1)
			else:
				surface.add_vertex(v0);  surface.add_vertex(v1);  surface.add_vertex(s0)
				surface.add_vertex(v1);  surface.add_vertex(s1);  surface.add_vertex(s0)
