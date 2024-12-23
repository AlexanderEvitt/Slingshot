extends Node3D

var fired = false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("fire"):
		visible = true
		fired = true
		
	if fired:
		position = position + Vector3(0.01,0,0)
	else:
		position = Vector3(0.247,0.023,0)
		
	if position.length() > 2:
		fired = false
		visible = false
		print("reset")
		
