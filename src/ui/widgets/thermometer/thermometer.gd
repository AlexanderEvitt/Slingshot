@tool
class_name Thermometer
extends Control

@export var label_text : String
var text_label: Label
var num_label: Label
var progress_bar: Control

func _ready() -> void:
	text_label = get_node("UpperText/Label")
	num_label = get_node("LowerText/Label")
	progress_bar = get_node("Bar/Panel/Panel")
	
	text_label.text = label_text

func set_fill(variable: float,variable_text : String) -> void:
	# Sets the fill of the gauge to variable (0 to 1)
	# and the text to whatever you input
	variable = clamp(variable, 0.0, 1.0)
	progress_bar.anchor_top = 1.0 - variable
	num_label.text = variable_text
