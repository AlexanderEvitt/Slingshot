extends Panel

var text = ""
var value = 0
@export var variable_name : String

var label
var cover

# Called when the node enters the scene tree for the first time.
func _ready():
	label = get_node("Front/Label")
	cover = get_node("Cover")
	
	get_node("Front/Title").text = variable_name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	cover.rotation = -PI + PI*value
	label.text = text
