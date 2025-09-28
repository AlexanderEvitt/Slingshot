extends Node3D

var chamber1
var chamber2
var fan
var pencil

# Called when the node enters the scene tree for the first time.
func _ready():
	fan = get_node("Fan").get_active_material(0)
	pencil = get_node("Pencil").get_active_material(0)
	chamber1 = get_node("Light")
	chamber2 = get_node("Light2")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var power = ShipData.player_ship.throttle
	if power > 0:
		visible = true
		pencil.set_shader_parameter("alpha_intensity_factor",0.05/power)
		fan.set_shader_parameter("alpha_intensity_factor",0.05/power)
		chamber1.light_energy = 0.2*power/0.05
		chamber2.light_energy = 0.1*power/0.05
	else:
		visible = false
