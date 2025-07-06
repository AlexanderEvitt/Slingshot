extends Node3D

var parent_body

# Values used by children
@export var GM: float # standard gravitional parameter, km3/s2

# Input values to define the orbit
@export var a = 384000.0 # semi major axis, km
@export var e = 0.0 # eccentricity
@export var i = 0.0 # inclination, rad
@export var RAAN: float # right ascension of ascending node, rad
@export var argp: float # argument of periapsis, rad
@export var theta0: float # initial true anomaly

# Persistent values used for orbital calculations
var M: float # mean anomaly, rad
var T: float # period, seconds
var p: float # semi latus rectum
var sqrt_mu_over_p: float # what it says on the tin
# Coefficients of true anomaly approximation
var c1: float
var c2: float
var c3: float
var c4: float
var c5: float
var c6: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent_body = get_parent()
	var parent_mu = parent_body.GM
	
	# Assign values that will be reused during orbit calculations
	M = 0.0
	T = 2*PI*sqrt(pow(a,3.0)/parent_mu)
	p = a*(1 - pow(e,2.0))
	sqrt_mu_over_p = sqrt(parent_mu/p)
	
	c1 = (2.0*e - 0.25*pow(e,3.0) + (5.0/96.0)*pow(e,5.0))
	c2 = ((5.0/4.0)*pow(e,2.0) - (11.0/24.0)*pow(e,4.0) + (17.0/192.0)*pow(e,6.0))
	c3 = ((13.0/12.0)*pow(e,3.0) - (43.0/64.0)*pow(e,5.0))
	c4 = ((103.0/96.0)*pow(e,4.0) - (451.0/480.0)*pow(e,6.0))
	c5 = (1097.0/960.0)*pow(e,5.0)
	c6 = (1223.0/960.0)*pow(e,6.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position = calculate_self_position(SystemTime.t)

func fetch(time):
	# Global ref frame
	return parent_body.fetch(time) + calculate_self_position(time)
	
func calculate_self_position(time):
	# Calculate mean anomaly at time

	M = 2*PI*(time/T)
	
	# Approximate true anomaly at time
	# Uses https://books.google.com/books?id=OjH7aVhiGdcC&pg=PA212#v=onepage&q&f=false
	var theta = theta0 + M + c1*sin(M) + c2*sin(2*M) + c3*sin(3*M) + c4*sin(4*M) + c5*sin(5*M) + c6*sin(6*M)
	
	# Calculate radius and velocity relative to parent
	var r = p/(1 + e*cos(theta))
	#var vr = sqrt_mu_over_p*e*sin(theta)
	#var vt = sqrt_mu_over_p*(1 + e*cos(theta))
	
	# Transform into a vector form using rotations
	var Rthw = Basis()
	Rthw = Rthw.rotated(Vector3(0,0,1),theta+argp)
	var Ri = Basis()
	Ri = Ri.rotated(Vector3(1,0,0),i)
	var Rom = Basis()
	Rom = Rom.rotated(Vector3(0,0,1),RAAN)
	
	# Return position Rom*Ri*Rthw*Vector3(r,0,0)
	# For some reason the precision depends on the theta0? 0.3 is unstable, 0.0 is stable
	var pos = Rom*Ri*Rthw*Vector3(r,0,0)
	return pos
