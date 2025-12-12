extends Node3D

var chamber1
var chamber2
var fan
var pencil
var design_thrust

# Called when the node enters the scene tree for the first time.
func _ready():
	fan = get_node("Fan").get_active_material(0)
	pencil = get_node("Pencil").get_active_material(0)
	chamber1 = get_node("Light")
	chamber2 = get_node("Light2")
	
	design_thrust = 613280*50 # N


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var thrust = ShipData.player_ship.propulsion_calculator.main_thrust
	thrust = clamp(thrust,1e-20,1e99)
	if thrust > 0:
		visible = true
		pencil.set_shader_parameter("alpha_intensity_factor",design_thrust/thrust)
		fan.set_shader_parameter("alpha_intensity_factor",design_thrust/thrust)
		chamber1.light_energy = 0.4*thrust/design_thrust
		chamber2.light_energy = 0.1*thrust/design_thrust
	else:
		visible = false
