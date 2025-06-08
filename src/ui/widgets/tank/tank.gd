@tool
extends Node

@onready var fill = get_node("TankFill")
@export var color : Color
@export var text : String

func _ready():
	fill.modulate = color
	get_node("CenterContainer/Panel/Label").text = text

func set_fill(variable):
	fill.anchor_top = 1.0 - variable
