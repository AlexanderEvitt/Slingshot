extends MeshInstance3D

# References to children
@export var upper_clamp : Node3D
@export var lower_clamp : Node3D

# Whether this clamp is left or right
@export var rightness = 1

# How much/how fast to move the clamps
var back_off_distance = 1.0/1000.0
var squeeze_angle = 66.0
var animation_time = 1.0

func _ready():
	# Connect to signals
	ShipData.player_ship.rel_clamp.connect(release_clamps)
	ShipData.player_ship.att_clamp.connect(attach_clamps)
	
	# Attach clamps at startup
	attach_clamps()

func release_clamps():
	# Get a tween
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel(true)
	
	# Tween clamps to released point
	tween.tween_property(self, "position", Vector3(0,0,rightness*back_off_distance), animation_time)
	tween.tween_property(lower_clamp, "rotation_degrees", Vector3(0,0,0), animation_time)
	tween.tween_property(upper_clamp, "rotation_degrees", Vector3(0,0,0), animation_time)

func attach_clamps():
	# Get a tween
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel(true)
	
	# Tween clamps to released point
	tween.tween_property(self, "position", Vector3(0,0,0), animation_time)
	tween.tween_property(lower_clamp, "rotation_degrees", Vector3(1*rightness*squeeze_angle,0,0), animation_time)
	tween.tween_property(upper_clamp, "rotation_degrees", Vector3(-1*rightness*squeeze_angle,0,0), animation_time)
