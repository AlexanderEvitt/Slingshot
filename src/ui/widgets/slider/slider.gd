@tool
extends VBoxContainer

# Inputs unique to each slider
@export var top_text : String
@export var bottom_text : String
@export var bottom_carrot_label_text : String
@export var top_carrot_label_text : String
@export var green_zone_bounds : Vector2

# The two sliders that move along the zone
var bottom_carrot
var top_carrot
var bottom_carrot_label
var top_carrot_label

@onready var top_text_label = $TopText
@onready var bottom_text_label = $BottomText

func _ready():
	# Get references to the nodes that we need to move
	bottom_carrot = $MarginContainer/SliderBar/BottomCarrot
	top_carrot = $MarginContainer/SliderBar/TopCarrot
	bottom_carrot_label = bottom_carrot.get_node("Label")
	top_carrot_label = top_carrot.get_node("Label")
	
	# Set the titles text appropriately
	if top_text.length() > 0:
		top_text_label.text = top_text
		top_text_label.visible = true
	if bottom_text.length() > 0:
		bottom_text_label.text = bottom_text
		bottom_text_label.visible = true
		
	# Set the carat text
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
	
func set_labels(new_top_text,new_bottom_text):
	if new_top_text.length() > 0:
		top_text_label.text = new_top_text
		top_text_label.visible = true
	if new_bottom_text.length() > 0:
		bottom_text_label.text = new_bottom_text
		bottom_text_label.visible = true
