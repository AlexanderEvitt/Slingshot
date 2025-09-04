extends Drawer

@export var color: Color
var line_instance = MeshInstance3D.new()


func _process(delta):
	# Add each point to traj
	var traj = []
	for x in ShipData.player_ship.waypoints:
		var body = get_tree().root.get_node("GameRoot/" + x["Frame"])
		var pos = x["Position"] + body.fetch(SystemTime.t) # relative to solar system origin
		traj.append(pos)
		
	undraw(line_instance)
	line_instance = line(traj, color)
	draw(self,line_instance)
