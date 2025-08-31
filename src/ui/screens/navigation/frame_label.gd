extends Label

func _ready():
	set_frame()

func _process(_delta):
	set_frame()

func set_frame():
	# Get frame, set as text in appropriate format
	if Input.is_action_just_released("next_frame"):
		var frame_name = Conversions.bodies[Conversions.f].name
		self.text = frame_name.to_upper() + "_CENTER_INERTIAL"
