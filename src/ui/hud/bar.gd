extends Sprite2D

@export var pos = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label1.text = str(pos)
	$Label2.text = str(pos)
	
	position.y = -(1920/50)*pos/2
	
	if pos != 0:
		$Otherside.visible = false
