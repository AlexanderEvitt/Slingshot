extends Panel


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("switch_camera"):
		get_node("MainUI").visible = !get_node("MainUI").visible
		get_node("FPVUI").visible = !get_node("FPVUI").visible
