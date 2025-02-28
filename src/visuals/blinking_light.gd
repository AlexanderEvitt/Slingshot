extends Node3D

var period = 1
var c = 0

var light
var emit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	light = get_node("Light")
	emit = get_node("Emit")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	c += delta
	
	if c > period:
		light.visible = !light.visible
		emit.visible = !emit.visible
		c = 0
