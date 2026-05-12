class_name QuadTreeNode
extends RefCounted

# Number of vertices per edge on each chunk's mesh.
# Higher = more geometric detail per chunk, but exponentially more triangles.
# Each chunk produces RESOLUTION^2 * 2 triangles.
# 64 = 8192 triangles per chunk — a reasonable balance.
const RESOLUTION := 16

# Maximum quadtree recursion depth.
# Each level doubles the mesh resolution of the planet surface.
# At depth N, a chunk covers (radius * 2) / 2^N units of arc.
# With radius=1737.4 and MAX_DEPTH=12, the smallest chunk is ~0.85 km wide.
const MAX_DEPTH := 1

# How aggressively to split. A node splits when:
#   (chunk_world_size / camera_distance) > SPLIT_THRESHOLD
# Lower = splits sooner (more detail at greater distance, more expensive).
# Higher = splits later (less detail, cheaper).
const SPLIT_THRESHOLD := 0.5

# How aggressively to merge. A node merges when:
#   (chunk_world_size / camera_distance) < MERGE_THRESHOLD
# Must be strictly less than SPLIT_THRESHOLD to prevent a node from
# oscillating between split and merged every frame (hysteresis gap).
const MERGE_THRESHOLD := 0.3

var face_normal: Vector3
var axis_a: Vector3
var axis_b: Vector3
var local_center: Vector2
var half_size: float
var depth: int

var children: Array[QuadTreeNode] = []
var chunk: PlanetChunk

var planet_root: Node3D
var sampler: HeightmapSampler
var radius: float
var displacement_scale: float
var surface_material: Material
var build_queue: Array  # reference to PlanetRoot's queue

var pending_build: bool = false

func init(
	p_face_normal: Vector3,
	p_local_center: Vector2,
	p_half_size: float,
	p_depth: int,
	p_planet_root: Node3D,
	p_sampler: HeightmapSampler,
	p_radius: float,
	p_displacement_scale: float,
	p_surface_material: Material,
	p_build_queue: Array
) -> void:
	face_normal = p_face_normal
	axis_a = Vector3(face_normal.y, face_normal.z, face_normal.x)
	axis_b = face_normal.cross(axis_a)
	local_center = p_local_center
	half_size = p_half_size
	depth = p_depth
	planet_root = p_planet_root
	sampler = p_sampler
	radius = p_radius
	displacement_scale = p_displacement_scale
	surface_material = p_surface_material
	build_queue = p_build_queue

func is_leaf() -> bool:
	return children.is_empty()

func get_world_center() -> Vector3:
	var cube_point := face_normal \
		+ axis_a * local_center.x \
		+ axis_b * local_center.y
	return cube_point.normalized() * radius

func get_world_size() -> float:
	return half_size * radius * 2.0

func update(camera_pos: Vector3) -> void:
	var dist := camera_pos.distance_to(get_world_center())
	var ratio := get_world_size() / dist

	if is_leaf():
		# Don't try to split while a build is already pending
		if pending_build:
			return
		if ratio > SPLIT_THRESHOLD and depth < MAX_DEPTH:
			split()
	else:
		if ratio < MERGE_THRESHOLD:
			merge()
		else:
			for child in children:
				child.update(camera_pos)

# Enqueues this node for building — does not build immediately
func build() -> void:
	if chunk != null or pending_build:
		return
	pending_build = true
	build_queue.append(self)

# Called by PlanetRoot._process() — actually constructs the mesh
func execute_build() -> void:
	pending_build = false
	if chunk != null:
		return
	chunk = PlanetChunk.new()
	chunk.face_normal = face_normal
	chunk.local_center = local_center
	chunk.half_size = half_size
	chunk.resolution = RESOLUTION
	chunk.radius = radius
	chunk.displacement_scale = displacement_scale
	chunk.sampler = sampler
	chunk.surface_material = surface_material
	planet_root.add_child(chunk)

func split() -> void:
	if not is_leaf():
		return
	_destroy_chunk()
	var hs := half_size * 0.5
	var offsets := [
		Vector2(-hs, -hs),
		Vector2( hs, -hs),
		Vector2(-hs,  hs),
		Vector2( hs,  hs),
	]
	for offset: Vector2 in offsets:
		var child := QuadTreeNode.new()
		child.init(face_normal, local_center + offset, hs, depth + 1,
				planet_root, sampler, radius, displacement_scale,
				surface_material, build_queue)
		child.build()
		children.append(child)

func merge() -> void:
	if is_leaf():
		return
	for child in children:
		child._recursive_destroy()
	children.clear()
	build()

func _recursive_destroy() -> void:
	if is_leaf():
		_destroy_chunk()
	else:
		for child in children:
			child._recursive_destroy()
		children.clear()

func _destroy_chunk() -> void:
	pending_build = false
	if chunk != null:
		chunk.queue_free()
		chunk = null
