extends Panel

var text = ""
var value = 0
@export var variable_name : String
@export var flipped : bool

var adder

var label
var cover

# Called when the node enters the scene tree for the first time.
func _ready():
	label = get_node("Front/Label")
	cover = get_node("Cover")
	
	get_node("Front/Title").text = variable_name
	adder = 1
	
	if flipped:
		$"Back".flip_h = true;
		$"Front".flip_h = true;
		$"Red".flip_h = true
		$"Green".flip_h = true
		$"Yellow".flip_h = true
		$"Cover".flip_h = true
		$"Green".rotation = -$"Green".rotation
		$"Yellow".rotation = -$"Yellow".rotation
		$"Red".rotation = -$"Red".rotation
		$"Front/Label".set_anchor_and_offset(SIDE_LEFT,0,0)
		$"Front/Label".set_anchor_and_offset(SIDE_RIGHT,1,-200)
		$"Front/Label".horizontal_alignment = 2
		adder = -1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	cover.rotation = -PI + adder*PI*value
	label.text = text
