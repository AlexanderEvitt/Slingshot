extends Drawer

@export var color: Color
var c = 0
var n = 100.0
var positions = [Vector3(0,0,0),Vector3(0,0,0)]
var old_positions = positions
var line_instance = MeshInstance3D.new()

func _process(_delta):
	# Only update when new positions are provided
	if old_positions != positions:
		var slicer = positions.size()/1000
		undraw(line_instance)
		
		line_instance = line(positions.slice(0,positions.size(),slicer), color)
		draw(line_instance)
		old_positions = positions
