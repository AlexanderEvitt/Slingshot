extends Label

var offset = 0 # time to subtract from SystemTime.t

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	self.text = format_time(SystemTime.t - offset)

func format_time(seconds):
	var signs := "T+"
	if seconds < 0:
		signs = "T-"
		seconds = abs(seconds)

	# Break down
	seconds = int(seconds)
	var days := int(seconds / 86400)
	var hours := int((seconds % 86400) / 3600)
	var minutes := int((seconds % 3600) / 60)
	var secs := int(seconds % 60)

	# Cap days at 99
	if days > 99:
		return "%s99d23h59m59s" % signs

	return "%s%02dd%02dh%02dm%02ds" % [signs, days, hours, minutes, secs]

func _on_reset():
	offset = SystemTime.t
