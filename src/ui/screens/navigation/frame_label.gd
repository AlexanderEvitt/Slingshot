extends Label

func _ready():
	set_frame()

func _process(_delta):
	set_frame()

func set_frame():
	# Get frame, set as text in appropriate format
	var frame_name = Conversions.frame_name.split("/")[-1] # slice out last thing in frame path
	self.text = frame_name.to_upper() + "_CENTER_INERTIAL"
