extends Drawer

@export var color: Color
var line_instance := MeshInstance3D.new()
@onready var orbit_root: Node3D = get_parent()
var waypoint_marker_scene := preload("res://scenes/orbit/waypoint_marker.tscn")

func _ready() -> void:
	ShipData.player_ship.waypoints_updated.connect(update_marker)

func _process(_delta: float) -> void:
	# Move node to where the camera is (global origin)
	# Lines use graphics that don't have double precision
	global_position = Vector3(0,0,0)
	
	# Add each point to traj
	var traj: Array[Vector3] = []
	for x in ShipData.player_ship.waypoints:
		var body: Body = x["Frame"]
		# Position is relative to the camera, which is always at the global origin
		# (position relative to selection) + (position selection relative to system) + (position system relative to floating origin)
		var pos: Vector3 = x["Position"] + body.fetch(SimTime.t) + orbit_root.position # relative to physics position
		traj.append(pos)
	
	# Cull the previous trajectory
	if line_instance != null:
		undraw(line_instance)
	
	# Draw the trajectory if there are at least two points to draw
	if traj.size() > 1:
		line_instance = line(traj, color)
		draw(self,line_instance)
		
	# Set the waypoint marker locations
	var c := 0
	for child in get_children():
		# Set position from waypoints arrray
		if child is Sprite3D:
			var typed_child := child as Sprite3D
			typed_child.position = traj[c]
			c += 1

func update_marker() -> void:
	# Free all current children
	for child in get_children():
		child.queue_free()
		
	# Add some children for current waypoints
	for i in range(ShipData.player_ship.waypoints.size()):
		var marker: Sprite3D = waypoint_marker_scene.instantiate()
		add_child(marker)
