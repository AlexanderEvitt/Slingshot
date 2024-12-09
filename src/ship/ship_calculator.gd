extends Node

var position
var velocity
var attitude

var thrust = 0

@export var start_position : Vector3
@export var start_velocity : Vector3

var attitude_calculator


# this module moves data from the master scene an autoload where others can access it

func _ready():
	attitude_calculator = get_node("AttitudeCalculator")
	
	# Initialize values
	attitude = attitude_calculator.transform.basis
	position = Conversions.ToUniversal(start_position)
	velocity = Conversions.VelToFrame(start_velocity)
	print(velocity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Change throttle setting
	if Input.is_action_just_pressed("full_throttle"):
		thrust = 20
	if Input.is_action_just_pressed("cut_throttle"):
		thrust = 0
		
	# Somehow get the acceleration from gravity in here
	var gravity = get_node("/root/GameRoot/")
	
	
	var dt = delta*SystemTime.step;
	
	# Update values
	attitude = attitude_calculator.transform.basis
	
	# Calculate acceleration on vehicle
	var acceleration = thrust*attitude.x
	
	# Calculate updated position and velocity through numerical integration
	position = position + velocity*dt
	velocity = velocity + acceleration*dt
	
