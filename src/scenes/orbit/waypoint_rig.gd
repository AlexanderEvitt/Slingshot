class_name WaypointRig
extends Drawer

@export var color: Color
var line_instance: MeshInstance3D = MeshInstance3D.new()
var select_mode := false
var camera_rig: Node3D
var hit: Vector3
var xy_hit: Vector3  # position locked after first click
var click_count := 0  # 0 = no clicks, 1 = xy locked, 2 = complete

func _process(_delta: float) -> void:
	var traj: Array[Vector3] = []
	traj.append(Vector3(0, 0, 0))

	if select_mode:
		var camera: Camera3D = camera_rig.get_node("CameraRotator/Camera3D")
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var from: Vector3 = camera.global_position - global_position
		var dir: Vector3 = camera.project_ray_normal(mouse_pos)

		if click_count == 0:
			# First click not yet placed — intersect with xy-plane
			var plane := Plane(Vector3(0, 0, 1), 0.0)
			var untyped_hit: Variant = plane.intersects_ray(from, dir)
			if untyped_hit != null:
				hit = untyped_hit
				visible = true
				traj.append(hit)
			else:
				visible = false
				traj.append(Vector3(0, 0, 0))

		elif click_count == 1:
			# xy is locked — intersect with vertical plane through xy_hit
			# The vertical plane passes through xy_hit and faces the camera's
			# horizontal direction, so dragging up/down moves along Z
			var vertical_plane_normal := Vector3(dir.x, dir.y, 0.0).normalized()
			var vertical_plane := Plane(vertical_plane_normal, vertical_plane_normal.dot(xy_hit))
			var untyped_z_hit: Variant = vertical_plane.intersects_ray(from, dir)
			if untyped_z_hit != null:
				var z_hit: Vector3 = untyped_z_hit
				# Keep xy from first click, only take z from second
				hit = Vector3(xy_hit.x, xy_hit.y, z_hit.z)
				visible = true
				traj.append(xy_hit)   # line goes through xy point...
				traj.append(hit)      # ...then up/down to final position
			else:
				traj.append(xy_hit)
				traj.append(xy_hit)

		undraw(line_instance)
		line_instance = line(traj, color)
		draw(self, line_instance)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == 1 and mouse_event.pressed and select_mode:
			if click_count == 0:
				# First click — lock xy position
				if hit != null:
					xy_hit = hit
					click_count = 1

			elif click_count == 1:
				# Second click — finalize z position and commit
				select_mode = false
				visible = false
				click_count = 0

				if hit != null:
					var selected_body_inheritor: BodyInheritor = get_parent()
					var frame_body: Node3D = ShipData.sim_root.get_node(selected_body_inheritor.body_path)
					ShipData.player_ship.waypoints.append({"Frame": frame_body, "Position": hit})
					ShipData.player_ship.waypoints_updated.emit()

# Call this when entering selection mode to reset state
func begin_selection() -> void:
	select_mode = true
	click_count = 0
	hit = Vector3.ZERO
	xy_hit = Vector3.ZERO
	visible = true
