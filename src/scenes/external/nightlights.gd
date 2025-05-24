extends MeshInstance3D

@export var sun_path : Node
var mat

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mat = get_active_material(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var sun_dir = (sun_path.position - ShipData.player_ship.position).normalized();
	mat.set_shader_parameter("sun_dir",sun_dir)
