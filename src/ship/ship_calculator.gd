extends Node

var position
var velocity
var attitude

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Update values
	attitude = attitude_calculator.transform.basis
	position = position + Vector3(0,0,1)
	velocity = Vector3(0,0,0)
