extends MeshInstance3D

@export var up : bool
@export var down : bool
@export var left : bool
@export var right : bool
@export var roll_left : bool
@export var roll_right : bool


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	visible = false
	if up:
		if Input.is_action_pressed("up"):
			visible = true
	if down:
		if Input.is_action_pressed("down"):
			visible = true
	if left:
		if Input.is_action_pressed("left"):
			visible = true
	if right:
		if Input.is_action_pressed("right"):
			visible = true
	if roll_left:
		if Input.is_action_pressed("roll_left"):
			visible = true
	if roll_right:
		if Input.is_action_pressed("roll_right"):
			visible = true
