extends Node

# Fuel quantity (kg)
var he_quant = 1.0
var de_quant = 1.0


# Total thrust applied to vehicle, including thrusters
var thrust = Vector3(0,0,0) # in ship frame
# Commanded acceleration from main engine only
var commanded_throttle = 0.0

var thruster_power = 0.005
var engine_power = 0.05

var fuel_burn_rate = 0.00001

@onready var ship = get_parent()

func update(_dt: float) -> void:
	thrust = Vector3(0,0,0)
	
	# Input main engine commanded throttle
	if Input.is_action_pressed("increment_throttle"):
		commanded_throttle = commanded_throttle + 0.001
	if Input.is_action_pressed("decrement_throttle"):
		commanded_throttle = commanded_throttle - 0.001
	if ship.nav_flag and ship.autopilot_flag:
		commanded_throttle = ship.navigation_calculator.control_throttle
	commanded_throttle = clamp(commanded_throttle,0,engine_power)
	
	# Simulate engine if time rate is 1
	if SystemTime.step == 1:
		# Increment pump speed based on error between throttle and result
		pass
	else:
		# At other time rates, just directly set the throttle
		pass
	

	
	# Add thruster inputs to thrust
	if Input.is_action_pressed("translate_left"):
		thrust = thrust + thruster_power*Vector3(0,0,-1)
	if Input.is_action_pressed("translate_right"):
		thrust = thrust + thruster_power*Vector3(0,0,1)
	if Input.is_action_pressed("translate_up"):
		thrust = thrust + thruster_power*Vector3(0,1,0)
	if Input.is_action_pressed("translate_down"):
		thrust = thrust + thruster_power*Vector3(0,-1,0)
	if Input.is_action_pressed("translate_fore"):
		thrust = thrust + thruster_power*Vector3(1,0,0)
	if Input.is_action_pressed("translate_aft"):
		thrust = thrust + thruster_power*Vector3(-1,0,0)
