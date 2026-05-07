@tool
class_name PlanetChunk
extends Node3D

@export var surface_material: Material

@export var resolution: int = 16:
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

	var axis_a: Vector3 = Vector3(f_normal.y, f_normal.z, f_normal.x)
	var axis_b: Vector3 = f_normal.cross(axis_a)

	# Precompute all vertices and UVs once
	var verts: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	verts.resize((resolution + 1) * (resolution + 1))
	uvs.resize((resolution + 1) * (resolution + 1))

	for y in range(resolution + 1):
		for x in range(resolution + 1):
			var cube_point := _local(x, y, f_normal, axis_a, axis_b)
			var unit_dir := cube_point.normalized()
			verts[y * (resolution + 1) + x] = _displaced_vertex_from_dir(unit_dir, r)
			uvs[y * (resolution + 1) + x] = _dir_to_uv(unit_dir)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	for y in range(resolution):
		for x in range(resolution):
			var i00 := y * (resolution + 1) + x
			var i10 := i00 + 1
			var i01 := i00 + (resolution + 1)
			var i11 := i01 + 1

			surface.set_uv(uvs[i00]); surface.add_vertex(verts[i00])
			surface.set_uv(uvs[i01]); surface.add_vertex(verts[i01])
			surface.set_uv(uvs[i10]); surface.add_vertex(verts[i10])
			surface.set_uv(uvs[i10]); surface.add_vertex(verts[i10])
			surface.set_uv(uvs[i01]); surface.add_vertex(verts[i01])
			surface.set_uv(uvs[i11]); surface.add_vertex(verts[i11])

	surface.generate_normals()
	_add_skirts(surface, f_normal, axis_a, axis_b, r)
	mesh_instance.mesh = surface.commit()

	if surface_material != null:
		mesh_instance.material_override = surface_material

# Now just a convenience wrapper used by _add_skirts
func _displaced_vertex(x: int, y: int, face: Vector3, a: Vector3, b: Vector3, r: float) -> Vector3:
	var cube_point := _local(x, y, face, a, b)
	return _displaced_vertex_from_dir(cube_point.normalized(), r)

func _displaced_vertex_from_dir(unit_dir: Vector3, r: float) -> Vector3:
	var elevation_km := 0.0
	if sampler != null:
		var normalized := sampler.sample(unit_dir)
		# Undo Godot's normalization, remove +20000 half-meter offset, convert to km
		elevation_km = (normalized * 65535.0 - 20000.0) * 0.0005
	return unit_dir * (r + elevation_km * displacement_scale)

# Converts a point on the unit sphere to equirectangular UV
func _dir_to_uv(unit_dir: Vector3) -> Vector2:
	var lon := atan2(unit_dir.x, unit_dir.z)
	var lat := asin(clampf(unit_dir.y, -1.0, 1.0))
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

	for edge: Dictionary in edges:
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
