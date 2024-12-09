extends Drawer

@export var period: float # days
@export var color: Color
var c = 0
var n = 64.0
var indent = 0.02
var tc = 0
var line_instance = MeshInstance3D.new()

func _ready():
	period = period*24*60*60

func _process(_delta):
	tc = SystemTime.t;
	
	var planet = get_parent()
	var traj = []
	for i in range(0,n):
		var t = tc + (indent)*period + ((1 - 2*indent)*period*i/n)
		
		traj.append(planet.fetch(t))
	
	# Remove previous line, create new line, draw new line
	undraw(line_instance)
	line_instance = line(traj, color)
	draw(line_instance)
 
