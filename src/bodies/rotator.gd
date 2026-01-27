extends MeshInstance3D

var period := 86400.0
func _process(_delta: float) -> void:
	rotate_z(SimTime.step*0.03333*2*PI/period)
