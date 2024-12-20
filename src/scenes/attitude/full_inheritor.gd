extends Node3D

var body

# Called when the node enters the scene tree for the first time.
func _ready():
	body = get_node("Body")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = OwnShip.position/1000
	body.transform.basis = OwnShip.attitude
