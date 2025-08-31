extends Label

func _process(_delta):
	# Process time rate into a string of text
	var step = SystemTime.step
	var millions = int(step/1e6)
	var thousands = int(step/1e3)
	if millions > 0:
		self.text = "x" + str(millions) + "m"
	elif thousands > 0:
		self.text = "x" + str(thousands) + "k"
	else:
		self.text = "x" + str(step)
