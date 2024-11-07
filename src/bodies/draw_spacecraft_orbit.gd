extends Drawer

@export var color: Color
var c = 0
var n = 100.0
var positions = [Vector3(0,0,0),Vector3(0,0,0)]
var old_positions = positions

func _process(_delta):
	# Only update when new positions are provided
	if old_positions != positions:
		var slicer = positions.size()/1000
		line(positions.slice(0,positions.size(),slicer), color, 0)
		old_positions = positions
