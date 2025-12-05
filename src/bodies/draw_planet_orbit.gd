extends Drawer

@export var color: Color
@export var visible_distance = 0
var c = 0
var n = 48
var indent = 0.0
var tc = 0
var line_instance = MeshInstance3D.new()
var period
@onready var this_body = get_parent()
@onready var parent_body = get_parent().get_parent()

var accumulator = 1e99 # so that all orbits are calculated in the first frame

func _process(_delta):
	# Only refresh when more time has elapsed than 1/2e5 of a period
	accumulator += SystemTime.step*0.03333;
	period = this_body.body.period
	var refresh_period = clamp(period/2e5, 30, 1e99)
	if accumulator > refresh_period: # <= how many times the orbit is redrawn per orbit
		refresh_traj()
		accumulator = 0
		

func refresh_traj():
	tc = SystemTime.t;
	
	var traj = []
	
	# Subtract start position of planet
	# Positions are relative to where the planet currently is
	var p0 = this_body.fetch(SystemTime.t)
	
	for i in range(0,n):
		var t = tc + (indent)*period + ((1 - indent)*period*i/n)
		var p = this_body.fetch(t) - p0
		
		# Subtract parent motion since start
		p = p - (parent_body.fetch(t) - parent_body.fetch(tc))

		traj.append(p)
	
	# Remove previous line, create new line, draw new line
	undraw(line_instance)
	
	# Set the alpha to fade out as distance increases
	if visible_distance != 0:
		var cam = get_viewport().get_camera_3d()
		var dist = (cam.global_position - parent_body.global_position)
		if dist.length() < visible_distance:
			color = Color(color, 1)
		elif dist.length() < 2*visible_distance:
			color = Color(color,1 - (dist.length() - visible_distance)/visible_distance)
		else:
			color = Color(color, 0)
	
	line_instance = line(traj, color)
	draw(self,line_instance)
 
