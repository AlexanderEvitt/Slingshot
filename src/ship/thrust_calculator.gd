extends Node


var thrust = Vector3(0,0,0) # in ship frame
var throttle = 0

var thruster_power = 0.005
var engine_power = 0.05
var attitude

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	thrust = Vector3(0,0,0)
	
	# Main engine thrust
	if Input.is_action_pressed("increment_throttle"):
		throttle = throttle + 0.001
	if Input.is_action_pressed("decrement_throttle"):
		throttle = throttle - 0.001
	throttle = clamp(throttle,0,engine_power)
	thrust = thrust + Vector3(throttle,0,0)
	
	# Thruster thrust
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
