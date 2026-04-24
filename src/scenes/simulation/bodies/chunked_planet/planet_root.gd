@tool
class_name PlanetRoot
extends Node3D

const FACE_NORMALS := [
	Vector3.UP, Vector3.DOWN,
	Vector3.LEFT, Vector3.RIGHT,
	Vector3.FORWARD, Vector3.BACK
]
const PLANET_RADIUS := 1737.4
const DISPLACEMENT_SCALE := 20.0
const HEIGHTMAP_PATH := "res://scenes/simulation/bodies/chunked_planet/moon_height.png"

@export var lod_target: Node3D:
	set(v):
		lod_target = v
		if Engine.is_editor_hint():
			_rebuild()

var trees: Array[QuadTreeNode] = []
var sampler: HeightmapSampler

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	# Clear any existing trees
	for tree in trees:
		tree._recursive_destroy()
	trees.clear()

	sampler = HeightmapSampler.new()
	if not sampler.load_from_path(HEIGHTMAP_PATH):
		push_error("PlanetRoot: heightmap failed to load")
		return
	for normal in FACE_NORMALS:
		var root := QuadTreeNode.new()
		root.init(normal, Vector2.ZERO, 1.0, 0, self, sampler, PLANET_RADIUS, DISPLACEMENT_SCALE)
		root.build()
		trees.append(root)

func _process(_delta: float) -> void:
	if lod_target == null:
		return
	var target_pos := lod_target.global_position
	for tree in trees:
		tree.update(target_pos)
