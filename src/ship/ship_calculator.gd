extends Node

var position
var velocity
var attitude

var plotted_positions

var thrust = 0

@export var start_position : Vector3
@export var start_velocity : Vector3

var attitude_calculator

# Autopilot modes
var current_mode
var inv_flag
var stab_flag
var autopilot_flag
var nav_flag


# this module moves data from the master scene an autoload where others can access it

func _ready():
	attitude_calculator = get_node("AttitudeCalculator")
	
	# Initialize values
	attitude = attitude_calculator.transform.basis
	position = Conversions.ToUniversal(start_position,0)
	velocity = Conversions.VelFromFrame(start_velocity,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Update values
	attitude = attitude_calculator.transform.basis
	
	# Change throttle setting
	if Input.is_action_just_pressed("full_throttle"):
		thrust = 0.05
	if Input.is_action_just_pressed("cut_throttle"):
		thrust = 0
	
	var dt = SystemTime.step*delta; # multiply by SystemTime.step if Engine.timescale isn't scaled
	
	# Somehow get the acceleration from gravity in here
	var gravity = get_node("Propagator").Acceleration(position,SystemTime.t)
	var next_gravity = get_node("Propagator").Acceleration(position,SystemTime.t + dt)
	
	# Calculate acceleration on vehicle
	var acceleration = thrust*attitude.x + gravity
	var next_acceleration = thrust*attitude.x + next_gravity
	
	# Calculate updated position and velocity through Verlet integration
	position = position + velocity*dt + 0.5*acceleration*dt**2
	velocity = velocity + 0.5*(acceleration+next_acceleration)*dt
