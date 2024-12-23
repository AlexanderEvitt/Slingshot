extends VBoxContainer

var reftext

# Called when the node enters the scene tree for the first time.
func _ready():
	reftext = get_node("RefText")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_released("next_frame"):
		reftext.text = Conversions.bodies[Conversions.f].name
