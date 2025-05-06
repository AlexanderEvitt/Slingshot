extends Panel

@export var toggled : bool
var previously_toggled : bool

# Set status text
@export var on_text : String
@export var off_text : String


func _process(_delta: float) -> void:
	if previously_toggled != toggled:
		# if there's a mismatch, the light should change state
		_on_toggled()
	# Update to track previous state
	previously_toggled = toggled

func _on_toggled():
	if toggled:
		# Set the status box to green
		var new_style = StyleBoxFlat.new()
		new_style.bg_color = Color8(51, 255, 51, 255)
		self.add_theme_stylebox_override("panel",new_style)
		# Set text
		get_node("Label").text = on_text
	else:
		# Set the status box to red
		var new_style = StyleBoxFlat.new()
		new_style.bg_color = Color8(128, 0, 0, 255)
		self.add_theme_stylebox_override("panel",new_style)
		# Set text
		get_node("Label").text = off_text
