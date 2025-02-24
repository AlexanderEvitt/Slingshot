extends MeshInstance3D

var period = 86400

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	rotate_z(SystemTime.step*0.03333*2*PI/period)
