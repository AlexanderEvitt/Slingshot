@tool
extends MeshInstance3D

# Adjustable parameters
@export var radius: float = 1.0
@export var subdivisions: int = 2

# Asteroid params
@export var noise1: NoiseTexture2D
@export var noise2: NoiseTexture2D
@export var terrain_height1 = 0.1
@export var terrain_height2 = 0.1
@export var refresh = true

var count = 0
	

func _process(_delta):
	if count == 0:
		mesh = generate_icosphere()
	if count == 20000000000000000 and Engine.is_editor_hint() and refresh:
		count = -1
		print("refreshing")
	count += 1

func generate_icosphere() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Base icosahedron
	var vertices = []
	var indices = []
	_generate_icosahedron(vertices, indices)

	# Subdivide
	var vertex_map = {}
	for i in range(subdivisions):
		indices = _subdivide(vertices, indices, vertex_map)

	# Normalize to a sphere
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * radius

	# Loop through vertices and move by noise texture
	var image1 = noise1.get_image()
	var image2 = noise2.get_image()
	for i in range(vertices.size()):
		vertices[i] *= (1 + terrain_height1*image1.get_pixelv(511*_compute_uv(vertices[i])).v)
		vertices[i] *= (1 + terrain_height2*image2.get_pixelv(511*_compute_uv(vertices[i])).v)

	# Create surface from triangles
	for i in range(0, indices.size(), 3):
		for j in range(3):
			var v = vertices[indices[i + j]]
			st.set_uv(_compute_uv(v))
			st.add_vertex(v)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()

func _generate_icosahedron(vertices: Array, indices: Array):
	var phi = (1.0 + sqrt(5.0)) / 2.0  # Golden ratio
	var inv_norm = 1.0 / sqrt(1.0 + phi * phi)

	# Create 12 vertices of an icosahedron
	var raw_vertices = [
		Vector3(-1,  phi,  0), Vector3( 1,  phi,  0),
		Vector3(-1, -phi,  0), Vector3( 1, -phi,  0),
		Vector3( 0, -1,  phi), Vector3( 0,  1,  phi),
		Vector3( 0, -1, -phi), Vector3( 0,  1, -phi),
		Vector3( phi,  0, -1), Vector3( phi,  0,  1),
		Vector3(-phi,  0, -1), Vector3(-phi,  0,  1)
	]

	for v in raw_vertices:
		vertices.append(v * inv_norm)  # Normalize initial shape

	# Define the 20 faces (triangles)
	indices.append_array([
		0, 11, 5,  0, 5, 1,  0, 1, 7,  0, 7, 10,  0, 10, 11,
		1, 5, 9,  5, 11, 4,  11, 10, 2,  10, 7, 6,  7, 1, 8,
		3, 9, 4,  3, 4, 2,  3, 2, 6,  3, 6, 8,  3, 8, 9,
		4, 9, 5,  2, 4, 11,  6, 2, 10,  8, 6, 7,  9, 8, 1
	])

func _subdivide(vertices: Array, indices: Array, vertex_map: Dictionary) -> Array:
	var new_indices = []

	for i in range(0, indices.size(), 3):
		var a = indices[i]
		var b = indices[i + 1]
		var c = indices[i + 2]

		var ab = _get_middle_point(a, b, vertices, vertex_map)
		var bc = _get_middle_point(b, c, vertices, vertex_map)
		var ca = _get_middle_point(c, a, vertices, vertex_map)

		new_indices.append_array([
			a, ab, ca,
			b, bc, ab,
			c, ca, bc,
			ab, bc, ca
		])

	return new_indices

func _get_middle_point(p1: int, p2: int, vertices: Array, vertex_map: Dictionary) -> int:
	var key = str(min(p1, p2)) + "-" + str(max(p1, p2))

	if vertex_map.has(key):
		return vertex_map[key]

	var mid = (vertices[p1] + vertices[p2]).normalized()
	var index = vertices.size()
	vertices.append(mid)
	vertex_map[key] = index

	return index

func _compute_uv(v: Vector3) -> Vector2:
	# Spherical mapping to UV coordinates
	v = v / ((1 + terrain_height1)*(1 + terrain_height2))
	var u = 0.5 + atan2(v.z, v.x) / (2.0 * PI)
	var v_coord = 0.5 - asin(v.y) / PI
	return Vector2(u, v_coord)
