extends Drawer

@export var color: Color
var line_instance = MeshInstance3D.new()
@onready var game_root = get_tree().root.get_node("GameRoot/")
@onready var orbit_root = get_parent()

func _process(_delta):
	# Move node to where the camera is (global origin)
	global_position = Vector3(0,0,0)
	
	# Add each point to traj
	var traj = []
	for x in ShipData.player_ship.waypoints:
		var body = game_root.get_node(x["Frame"])
		# Position is relative to the camera, which is always at the global origin
		# (position relative to selection) + (position selection relative to system) + (position system relative to camera)
		var pos = x["Position"] + body.fetch(SystemTime.t) + orbit_root.position # relative to camera position
		traj.append(pos)
	
	# Cull the previous trajectory
	if line_instance != null:
		undraw(line_instance)
	
	# Draw the trajectory if there are at least two points to draw
	if traj.size() > 1:
		line_instance = line(traj, color)
		draw(self,line_instance)
