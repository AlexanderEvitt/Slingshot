extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	get_node("AttitudeLabelHolder/Label2").text = str(get_node("MarginCam/Panel/SubViewportContainer/SubViewport/AttitudeRoot/Spacecraft").transform.basis.get_rotation_quaternion())
	get_node("AttitudeLabelHolder/Label4").text = str(get_node("MarginCam/Panel/SubViewportContainer/SubViewport/AttitudeRoot/Spacecraft").angular_velocity)
