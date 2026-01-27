extends Label

func _ready() -> void:
	set_frame()

func _process(_delta: float) -> void:
	set_frame()

func set_frame() -> void:
	# Get frame, set as text in appropriate format
	var frame_name := Conversions.frame_name.split("/")[-1] # slice out last thing in frame path
	self.text = frame_name.to_upper() + "_CENTER_INERTIAL"
