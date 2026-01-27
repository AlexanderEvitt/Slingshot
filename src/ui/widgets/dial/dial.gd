@tool
class_name Dial
extends Control

@export var label_text : String
var text_label: Label
var num_label: Label
var progress_bar: TextureProgressBar

func _ready() -> void:
	text_label = get_node("TextureProgressBar/Label")
	num_label = get_node("TextureProgressBar/Label2")
	progress_bar = get_node("TextureProgressBar")
	
	text_label.text = label_text

func set_fill(variable: float,variable_text : String) -> void:
	# Sets the fill of the gauge to variable (0 to 1)
	# and the text to whatever you input
	progress_bar.value = variable
	num_label.text = variable_text
