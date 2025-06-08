@tool
class_name CircleGaugeWidget
extends Control

@export var label_text : String
var text_label
var num_label
var progress_bar

# Called when the node enters the scene tree for the first time.
func _ready():
	text_label = get_node("TextureProgressBar/Label")
	num_label = get_node("TextureProgressBar/Label2")
	progress_bar = get_node("TextureProgressBar")

func set_fill(variable):
	progress_bar.value = variable
