extends Label

func _process(_delta):
	# Process time rate into a string of text
	# Don't show up if the time rate is real time
	var step = SystemTime.step
	if step == 1:
		visible = false
	else:
		visible = true
		var millions = int(step/1e6)
		var thousands = int(step/1e3)
		if millions > 0:
			self.text = "×" + str(millions) + "m"
		elif thousands > 0:
			self.text = "×" + str(thousands) + "k"
		else:
			self.text = "×" + str(step)
