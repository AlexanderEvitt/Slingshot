extends Panel

var i = 0

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("switch_camera"):
		# Increment by 1, looping to zero
		i += 1
		i = i % 3
		
		# Set visibility of children
		var n = 0
		for child in get_children():
			if n == i:
				child.visible = true
			else:
				child.visible = false
			n += 1
