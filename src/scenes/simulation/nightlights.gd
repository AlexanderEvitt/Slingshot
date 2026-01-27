extends MeshInstance3D

@export var sun_path : Node3D # path to main Sun node
var mat: ShaderMaterial

func _ready() -> void:
	mat = get_active_material(0)


func _process(_delta: float) -> void:
	var sun_dir: Vector3 = (sun_path.position - ShipData.player_ship.position).normalized();
	mat.set_shader_parameter("sun_dir",sun_dir)
