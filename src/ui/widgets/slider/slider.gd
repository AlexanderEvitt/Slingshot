@tool
extends VBoxContainer

# Inputs unique to each slider
@export var title : String
@export var bottom_carrot_label_text : String
@export var top_carrot_label_text : String
@export var green_zone_bounds : Vector2

# The two sliders that move along the zone
var bottom_carrot
var top_carrot
var bottom_carrot_label
var top_carrot_label

func _ready():
	# Get references to the nodes that we need to move
	bottom_carrot = $MarginContainer/SliderBar/BottomCarrot
	top_carrot = $MarginContainer/SliderBar/TopCarrot
	bottom_carrot_label = bottom_carrot.get_node("Label")
	top_carrot_label = top_carrot.get_node("Label")
	
	# Set the text appropriately
	$Title.text = title
	bottom_carrot_label.text = bottom_carrot_label_text
	top_carrot_label.text = top_carrot_label_text
	
	# Set the green zone to its boundaries
	var green_section = $MarginContainer/SliderBar/GreenSection
	green_section.anchor_left = green_zone_bounds.x
	green_section.anchor_right = green_zone_bounds.y

func set_fill_bottom(variable):
	# Set the position of the lower slider
	bottom_carrot.anchor_left = variable
	bottom_carrot.anchor_right = variable
	
func set_fill_top(variable):
	# Set the position of the lower slider
	top_carrot.anchor_left = variable
	top_carrot.anchor_right = variable
