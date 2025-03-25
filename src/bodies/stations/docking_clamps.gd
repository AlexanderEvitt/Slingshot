extends MeshInstance3D

var station
var center
var drange = 0.005
@export var clamp_pos = Vector3(22.29,0,-7.4468)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	station = get_parent().get_parent().get_parent()
	center = get_viewport().get_child(0) # root of external scene
	
	clamp_pos = clamp_pos / 1000 # m to km


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Move to attach to ship
	var ship_global = OwnShip.position + center.global_position
	global_position = ship_global + OwnShip.attitude*clamp_pos
	
	# Clamp to a small range of motion
	position = position.clamp(Vector3(-drange,-drange,-3*drange),Vector3(drange,drange,3*drange))
	
