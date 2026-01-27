extends Label

var offset := 0.0 # time to subtract from SimTime.t

func _process(_delta: float) -> void:
	self.text = Conversions.format_time(SimTime.t - offset)

func _on_reset() -> void:
	offset = SimTime.t
