extends Drawer

@export var color: Color
@export var slice: bool
@export var squashed : bool
var c = 0
var n = 100.0
var positions
var old_positions = positions
var line_instance = MeshInstance3D.new()


func _process(_delta):
	# Only update when new positions are provided
	if old_positions != positions:
		if positions != null:
			var slicer = positions.size()/500.0 # look for 500 data points roughly
			slicer = ceil(slicer) # don't the step be zero though
			undraw(line_instance)
			
			if slice:
				line_instance = line(positions.slice(0,positions.size(),slicer), color, squashed)
			else:
				line_instance = line(positions, color, squashed)
			draw(line_instance)
			
			old_positions = positions
		else:
			# If positions become null, remove the line
			line_instance.queue_free()
	
	# Move with the spacecraft
	line_instance.position = get_parent().position
