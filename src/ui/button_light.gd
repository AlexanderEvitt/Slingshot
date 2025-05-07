extends Button

var light

func _ready():
	light = get_node("Panel")
	
	# send toggled signal to self
	self.button_down.connect(_on_toggled)

func _on_toggled():
	if button_pressed:
		# Set the status box to green
		var new_style = StyleBoxFlat.new()
		new_style.bg_color = Color8(51, 255, 51, 255)
		light.add_theme_stylebox_override("panel",new_style)
	else:
		# Set the status box to red
		var new_style = StyleBoxFlat.new()
		new_style.bg_color = Color8(128, 0, 0, 255)
		light.add_theme_stylebox_override("panel",new_style)
