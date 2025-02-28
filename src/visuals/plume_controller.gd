extends Node3D

var chamber
var tail

# Called when the node enters the scene tree for the first time.
func _ready():
	tail = get_node("Tail").get_active_material(0)
	chamber = get_node("Light")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var power = OwnShip.throttle
	if power > 0:
		visible = true
		tail.set_shader_parameter("alpha_intensity_factor",0.05/power)
		chamber.light_energy = 10*power/0.05
	else:
		visible = false
