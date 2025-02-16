extends Drawer

@export var color: Color
@export var slice: bool
@export var squashed : bool
var c = 0
var n = 100.0
var positions
var old_positions = positions
var line_instance = MeshInstance3D.new()

# Variables for shifting traj
var initial_planet_pos : Vector3
var original_traj_pos : Vector3

func _process(delta):
	# Only update when new positions are provided
	if old_positions != positions:
		if positions != null:
			var slicer = positions.size()/500.0 # look for 500 data points roughly
			slicer = ceil(slicer) # don't the step be zero though
			
			# Delete previous line if it exists
			if line_instance != null:
				undraw(line_instance)
			
			if slice:
				line_instance = line(positions.slice(0,positions.size(),slicer), color, squashed)
			else:
				line_instance = line(positions, color, squashed)
			draw(self,line_instance)
			
			# Set position to spacecraft's position
			original_traj_pos = OwnShip.position
			line_instance.position = Vector3(0,0,0)
			
			# Record position of planet
			initial_planet_pos = Conversions.FindFrame(SystemTime.t)
			
			old_positions = positions
		elif line_instance != null:
			# If positions become null, remove the line
			undraw(line_instance)
	
	# Move by how much the ref frame has moved since traj drawn
	if line_instance != null:
		line_instance.position -= Conversions.VelToFrame(OwnShip.velocity, SystemTime.t)*delta*SystemTime.step
