class_name Plotter
extends Drawer

@export var color: Color
var n := 100.0
var positions : Array[Vector3]
var old_positions := positions
var line_instance: MeshInstance3D = MeshInstance3D.new()

# Variables for shifting traj
var initial_planet_pos : Vector3
var original_traj_pos : Vector3

func _process(delta: float) -> void:
	# Only update when new positions are provided
	if old_positions != positions:
		if positions.size() > 0:
			# Delete previous line if it exists
			if line_instance != null:
				undraw(line_instance)

			line_instance = line(positions, color)
			draw(self,line_instance)
			
			# Set position to spacecraft's position
			original_traj_pos = ShipData.player_ship.position
			line_instance.position = Vector3(0,0,0)
			
			# Record position of planet
			initial_planet_pos = Conversions.find_body(SimTime.t)
			
			old_positions = positions
		elif line_instance != null:
			# If positions become null, remove the line
			undraw(line_instance)

	# Move by how much the ref frame has moved since traj drawn
	if line_instance != null:
		line_instance.position -= Conversions.velocity_inertial_to_body(ShipData.player_ship.velocity, SimTime.t)*delta*SimTime.step
