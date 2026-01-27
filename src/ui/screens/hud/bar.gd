extends Sprite2D

@export var pos := 0.0

func _ready() -> void:
	var label1: Label = $Label1
	var label2: Label = $Label2
	label1.text = str(pos)
	label2.text = str(pos)
	
	position.y = -(1920.0/50.0)*pos/2
	
	if pos != 0:
		var otherside: Sprite2D = $Otherside
		otherside.visible = false
