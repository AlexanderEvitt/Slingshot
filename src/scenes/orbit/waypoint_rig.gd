extends Drawer

@export var color: Color
var line_instance = MeshInstance3D.new()
var select_mode = false
var camera_rig # reference to the camera_rig, populated by the selection panel
var hit # most recent intersection between mouse pointer and plane at selected body


func _process(_delta):
	var traj = []
	traj.append(Vector3(0,0,0))
	
	if select_mode:
		# First get the mouse position in coordinates relative to the selected body
		var camera = camera_rig.get_node("CameraRotator/Camera3D")
		var mouse_pos = get_viewport().get_mouse_position()
		var from = -get_parent().global_position # this is the camera position relative to the selected body (camera is at world origin)
		var dir = camera.project_ray_normal(mouse_pos)
		var plane = Plane(Vector3(0,0,1), 0.0) # z=0 plane
		hit = plane.intersects_ray(from, dir)
		
		if hit != null:
			visible = true
			traj.append(hit)
		else:
			visible = false
			traj.append(Vector3(0,0,0))
		
		# Draw a line from the selection origin to the mouse
		undraw(line_instance)
		line_instance = line(traj, color)
		draw(self,line_instance)

func _input(event):
	# Listen for a click that would kick you out of selection mode
	# and write the last mouse position to the waypoint list
	if event is InputEventMouseButton and event.button_index == 1 and select_mode == true:
		select_mode = false
		visible = false
		
		# Pass to ship computer
		if hit != null:
			# Add to waypoints array
			ShipData.player_ship.waypoints.append({"Frame":get_parent().body_path, "Position":hit})
			# Emit waypoints_updated signal to alert nodes of update
			ShipData.player_ship.waypoints_updated.emit()
			
