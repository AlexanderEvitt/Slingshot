extends Drawer

@export var color: Color
@export var visible_distance := 0.0
var n := 128
var tc := 0.0
var line_instance := MeshInstance3D.new()
var period: float
@onready var this_body_inheritor: BodyInheritor = get_parent()
@onready var parent_body: Node3D = get_parent().get_parent()

var accumulator: float = INF # so all orbits are calculated in the first frame

func _process(delta: float) -> void:
	# Only refresh when more time has elapsed than 1 period
	accumulator += delta*SimTime.step
	period = this_body_inheritor.body.period
	
	if accumulator > period:
		refresh_traj()
		accumulator = 0
		
	# Move this node to the parent body's position
	global_position = parent_body.global_position

func refresh_traj() -> void:
	tc = SimTime.t;
	
	var traj: Array[Vector3] = []
	
	# Iterate through next 1 period
	for i in range(0,n+1):
		var t := tc + (period*i/n)
		var p: Vector3 = this_body_inheritor.body.get_local_position(t)
		traj.append(p)
	
	# Remove previous line, create new line, draw new line
	undraw(line_instance)
	
	line_instance = line(traj, color, visible_distance)
	draw(self,line_instance)
 
