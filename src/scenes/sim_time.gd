extends Node

var t0: int = 0
var t: float = 0.0
var prev_t: float = 0.0
var step: float = 0.0
var steps: Array[float] = [0.0, 1.0, 10.0, 100.0, 1000.0, 10000.0]
var i: int = 0

func _physics_process(delta: float) -> void:
	# Update time every frame
	prev_t = t
	step = steps[i]
	t = t + (step * delta)
	
	# Take input to accelerate or slow down time
	if Input.is_action_just_pressed("time_speed_up"):
		i += 1
	elif Input.is_action_just_pressed("time_speed_down"):
		i -= 1
	i = clampi(i, 0, steps.size() - 1)
