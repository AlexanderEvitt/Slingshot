@tool
class_name PlanetRoot
extends Node3D

const FACE_NORMALS := [
	Vector3.UP, Vector3.DOWN,
	Vector3.LEFT, Vector3.RIGHT,
	Vector3.FORWARD, Vector3.BACK
]
const PLANET_RADIUS := 1737.4
const DISPLACEMENT_SCALE := 1.0
const HEIGHTMAP_PATH := "res://scenes/simulation/bodies/chunked_planet/moon_height.png"

# Number of chunks to build per frame.
# Higher = faster LOD population but more frame stuttering.
# Lower = smoother framerate but chunks take longer to appear.
const BUILDS_PER_FRAME := 16

@export var lod_target: Node3D:
	set(v):
		lod_target = v
		if Engine.is_editor_hint():
			_rebuild()

@export var surface_material: Material:
	set(v):
		surface_material = v
		if Engine.is_editor_hint():
			_rebuild()

@export var enabled_in_editor: bool = false:
	set(v):
		enabled_in_editor = v
		if Engine.is_editor_hint():
			if enabled_in_editor:
				_rebuild()
			else:
				_clear()

var trees: Array[QuadTreeNode] = []
var sampler: HeightmapSampler
var build_queue: Array[QuadTreeNode] = []


func _ready() -> void:
	if Engine.is_editor_hint() and not enabled_in_editor:
		return
	_rebuild()

func _rebuild() -> void:
	for tree in trees:
		tree._recursive_destroy()
	trees.clear()
	build_queue.clear()

	sampler = HeightmapSampler.new()
	if not sampler.load_from_path(HEIGHTMAP_PATH):
		push_error("PlanetRoot: heightmap failed to load")
		return

	for normal: Vector3 in FACE_NORMALS:
		var root := QuadTreeNode.new()
		root.init(normal, Vector2.ZERO, 1.0, 0, self, sampler,
				PLANET_RADIUS, DISPLACEMENT_SCALE, surface_material, build_queue)
		root.build()
		trees.append(root)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and not enabled_in_editor:
		return
	if lod_target == null:
		return

	# Convert target world position to planet local space
	# so LOD is stable when the planet moves
	var local_target_pos := 1737.4*to_local(lod_target.global_position).normalized()

	for tree in trees:
		tree.update(local_target_pos)

	var built := 0
	while not build_queue.is_empty() and built < BUILDS_PER_FRAME:
		var node: QuadTreeNode = build_queue.pop_front()
		if node.chunk == null and node.is_leaf():
			node.execute_build()
			built += 1

func _clear() -> void:
	for tree in trees:
		tree._recursive_destroy()
	trees.clear()
	build_queue.clear()
