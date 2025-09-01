extends Area3D

@export var camera_rig : Node
@export var expandable : bool # whether the collider grows with camera zoom (planets do, moons don't)
@onready var collision_shape = $CollisionShape3D
var default_radius # whatever the radius of the planet is

func _ready():
	default_radius = collision_shape.shape.radius

func _process(_delta):
	# Adjust the radius of the collision shape
	if expandable:
		var adjusted_radius = camera_rig.zoom_distance*0.01745 # zoom*sin(1 deg)
		collision_shape.shape.radius = max(default_radius, adjusted_radius)
