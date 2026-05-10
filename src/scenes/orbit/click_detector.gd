extends Area3D

@export var expandable : bool # whether the collider grows with camera zoom (planets do, moons don't)
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var shape: SphereShape3D = collision_shape.shape
var default_radius: float # whatever the radius of the planet is

@onready var camera_rig: ExternalCameraRig = get_viewport().get_camera_3d().get_parent().get_parent()

func _ready() -> void:
	default_radius = shape.radius

func _process(_delta: float) -> void:
	# Adjust the radius of the collision shape
	if expandable:
		var adjusted_radius := camera_rig.zoom_distance*0.01745 # zoom*sin(1 deg)
		shape.radius = max(default_radius, adjusted_radius)
