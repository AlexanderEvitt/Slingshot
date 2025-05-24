extends Node3D

var origin
var pointing

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	origin = Conversions.FindFrame(SystemTime.t)
	pointing = origin - ShipData.player_ship.position
	look_at(pointing,Vector3(0,0,1))
