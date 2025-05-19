extends Node3D

var missiles
var launches
var velocities
var i = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	missiles = [$Missile1,$Missile2,$Missile3, $Missile4]
	launches = [0, 0, 0, 0]
	velocities = [0, 0, 0, 0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fire"):
		launches[i] = 1
		missiles[i].visible = true
		i += 1
		
	# Update velocities
	for ik in 4:
		velocities[ik] += delta*50*launches[ik]
		missiles[ik].position.x += delta*velocities[ik]
