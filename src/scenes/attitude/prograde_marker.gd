extends Sprite3D

var v
var cam
@export var retro : int

# Called when the node enters the scene tree for the first time.
func _ready():
	cam = get_parent().get_node("Viewpoint/Camera3D")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	v = Conversions.VelToFrame(OwnShip.velocity)
	position = retro*v.normalized()/2
	
	if (global_position.dot(cam.global_position)) > 0:
		visible = false
	else:
		visible = true
