extends Node3D

@export var body_path : String
@onready var body: Body = ShipData.sim_root.get_node(body_path)

func fetch(time: float) -> Vector3:
	return body.fetch(time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# Inherit position from main scene
	position = body.get_local_position(SimTime.t)
