class_name QuadTreeNode
extends RefCounted

const RESOLUTION := 16
const MAX_DEPTH := 8
const SPLIT_THRESHOLD := 1.5
const MERGE_THRESHOLD := 1.0  # must be < SPLIT_THRESHOLD to avoid thrashing

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

func init(
	p_face_normal: Vector3,
	p_local_center: Vector2,
	p_half_size: float,
	p_depth: int,
	p_planet_root: Node3D,
	p_sampler: HeightmapSampler,
	p_radius: float,
	p_displacement_scale: float
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

func is_leaf() -> bool:
	return children.is_empty()

# Returns approximate world-space center of this chunk
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
		if ratio > SPLIT_THRESHOLD and depth < MAX_DEPTH:
			split()
	else:
		if ratio < MERGE_THRESHOLD:
			merge()
		else:
			for child in children:
				child.update(camera_pos)

func build() -> void:
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
	for offset in offsets:
		var child := QuadTreeNode.new()
		child.init(face_normal, local_center + offset, hs, depth + 1,
				planet_root, sampler, radius, displacement_scale)
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
	if chunk != null:
		chunk.queue_free()
		chunk = null
