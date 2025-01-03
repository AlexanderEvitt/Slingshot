extends Drawer

@export var color: Color
@export var slice: bool
var c = 0
var n = 100.0
var positions
var old_positions = positions
var line_instance = MeshInstance3D.new()

func _process(_delta):
	# Only update when new positions are provided
	if old_positions != positions:
		
		var slicer = positions.size()/500
		undraw(line_instance)
		
		if slice:
			line_instance = line(positions.slice(0,positions.size(),slicer), color)
		else:
			line_instance = line(positions, color)
		draw(line_instance)
		
		old_positions = positions
	
	# Move with the spacecraft
	line_instance.position = get_parent().position
