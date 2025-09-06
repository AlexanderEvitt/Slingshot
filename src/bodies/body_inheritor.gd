extends Node3D

@export var body_path : String
var body : Node

# Called when the node enters the scene tree for the first time.
func _ready():
	body = get_tree().root.get_node("GameRoot/" + body_path)

func fetch(time):
	return body.fetch(time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Inherit position from main scene
	position = body.get_local_position(SystemTime.t)
