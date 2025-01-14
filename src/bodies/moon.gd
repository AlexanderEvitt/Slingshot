extends Node3D

var parent_body
@export var period : float
@export var true_anomaly: float
@export var SMA: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent_body = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position = calculate_self_position(SystemTime.t)/1000

func fetch(time):
	return parent_body.fetch(time) + calculate_self_position(time)
	
func calculate_self_position(time):
	var theta = (time/period)*2*PI + true_anomaly
	var pos = SMA*Vector3(cos(theta), sin(theta), 0)
	return pos
