extends Drawer

@export var period: float # days
@export var color: Color
@export var smashed: bool
@export var visible_distance = 0
var c = 0
var n = 48
var indent = 0.0
var tc = 0
var line_instance = MeshInstance3D.new()
var planet
@export var relative_to: Node3D

var accumulator = 1e99 # so that all orbits are calculated in the first frame

func _ready():
	period = period*24*60*60
	planet = get_parent()

func _process(_delta):
	# Only refresh when more time has elapsed than 1/1e6 of a period
	accumulator += SystemTime.step*0.03333;
	if accumulator > period/1e6: # <= how many times the orbit is redrawn per orbit
		refresh_traj()
		accumulator = 0
		

func refresh_traj():
	tc = SystemTime.t;
	
	var traj = []
	
	# Subtract start position of planet
	var p0 = planet.fetch(SystemTime.t)
	
	for i in range(0,n):
		var t = tc + (indent)*period + ((1 - indent)*period*i/n)
		var p = planet.fetch(t) - p0
		
		# If relative_to exists, subtract its velocity
		if relative_to != null:
			p = p - (relative_to.fetch(t) - relative_to.fetch(tc))
		
		if smashed:
			p.z = 0
		traj.append(p)
	
	# Remove previous line, create new line, draw new line
	undraw(line_instance)
	
	# Set the alpha to fade out as distance increases
	if visible_distance != 0:
		var cam = get_viewport().get_camera_3d()
		var dist = (cam.global_position - relative_to.global_position)
		if dist.length() < visible_distance:
			color = Color(color, 1)
		elif dist.length() < 2*visible_distance:
			color = Color(color,1 - (dist.length() - visible_distance)/visible_distance)
		else:
			color = Color(color, 0)
	
	line_instance = line(traj, color)
	draw(self,line_instance)
 
