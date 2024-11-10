extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	get_node("VBoxContainer/Label2").text = str(get_node("SubViewportContainer/SubViewport/AttitudeRoot/Spacecraft").transform.basis.get_rotation_quaternion())
	get_node("VBoxContainer/Label4").text = str(get_node("SubViewportContainer/SubViewport/AttitudeRoot/Spacecraft").angular_velocity)
