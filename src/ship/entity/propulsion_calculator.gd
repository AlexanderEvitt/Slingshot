extends Node

# Fuel quantity
var he_quant = 1.0
var de_quant = 1.0

# Pump speeds
var he_mp = 0.0
var de_mp = 0.0

# Main valve positions
var he_mv = false
var de_mv = false

# Total thrust applied to vehicle, including thrusters
var thrust = Vector3(0,0,0) # in ship frame
# Resulting acceleration from main engine only
var throttle = 0.0
# Commanded acceleration from main engine only
var commanded_throttle = 0.0

var thruster_power = 0.005
var engine_power = 0.05

var fuel_burn_rate = 0.00001


func _process(_delta: float) -> void:
	thrust = Vector3(0,0,0)
	
	# Input main engine commanded throttle
	if Input.is_action_pressed("increment_throttle"):
		commanded_throttle = commanded_throttle + 0.01
	if Input.is_action_pressed("decrement_throttle"):
		commanded_throttle = commanded_throttle - 0.01
	commanded_throttle = clamp(commanded_throttle,0,engine_power)
	
	# Increment pump speed based on error between throttle and result
	var Kp = 0.1
	var error = (commanded_throttle - throttle)/engine_power
	he_mp = he_mp + Kp*error
	de_mp = de_mp + Kp*error
	
	# Add in some random noise
	he_mp = he_mp
	de_mp = de_mp
	
	# Drain fuel by corresponding amount
	he_quant = he_quant - fuel_burn_rate*he_mp
	de_quant = de_quant - fuel_burn_rate*de_mp
		
	# Calculate thrust from pump speed
	throttle = engine_power*min(he_mp,de_mp) # lowest pump speed
	thrust = thrust + Vector3(throttle,0,0)
	
	# Zero thrust if fuel is empty
	if he_quant <= 0 or de_quant <= 0:
		throttle = 0
		commanded_throttle = 0
	
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
