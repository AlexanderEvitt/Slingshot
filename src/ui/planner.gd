extends MarginContainer

var propagator

# Called when the node enters the scene tree for the first time.
func _ready():
	propagator = get_tree().get_root().get_node("/root/GameRoot/Ships/OwnShip/Propagator")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_plan():
	# Zeroth order estimate of transfer time
	var target = Conversions.FindFrame(SystemTime.t)
	var transfer_dist = target - OwnShip.position;
	var transfer_time = 2*sqrt(transfer_dist.length()/0.05)
	
	# Calculate properly
	propagator.SMC(OwnShip.position,Conversions.FindFrame(SystemTime.t + transfer_time), OwnShip.velocity, SystemTime.t)
