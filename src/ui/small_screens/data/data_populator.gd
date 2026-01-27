extends Control

@onready var sclk: Label = $HBoxContainer/StateBox/GridContainer/Label2

@onready var rx: Label = $HBoxContainer/StateBox/GridContainer/Label4
@onready var ry: Label = $HBoxContainer/StateBox/GridContainer/Label6
@onready var rz: Label = $HBoxContainer/StateBox/GridContainer/Label8

@onready var vx: Label = $HBoxContainer/StateBox/GridContainer/Label10
@onready var vy: Label = $HBoxContainer/StateBox/GridContainer/Label12
@onready var vz: Label = $HBoxContainer/StateBox/GridContainer/Label14

@onready var thr: Label = $HBoxContainer/StateBox/GridContainer/Label16
@onready var g: Label = $HBoxContainer/StateBox/GridContainer/Label18

@onready var rotx: Label = $HBoxContainer/StateBox/GridContainer/Label20
@onready var roty: Label = $HBoxContainer/StateBox/GridContainer/Label22
@onready var rotz: Label = $HBoxContainer/StateBox/GridContainer/Label24

@onready var from: Label = $HBoxContainer/NavBox/GridContainer/Label18
@onready var to: Label = $HBoxContainer/NavBox/GridContainer/Label20

@onready var prog: Label = $HBoxContainer/NavBox/GridContainer/Label22
@onready var etw: Label = $HBoxContainer/NavBox/GridContainer/Label24
@onready var ete: Label = $HBoxContainer/NavBox/GridContainer/Label26

@onready var rplus: Label = $HBoxContainer/NavBox/GridContainer/Label28
@onready var rcross: Label = $HBoxContainer/NavBox/GridContainer/Label30

@onready var vplus: Label = $HBoxContainer/NavBox/GridContainer/Label32
@onready var vcross: Label = $HBoxContainer/NavBox/GridContainer/Label34

@onready var aplus: Label = $HBoxContainer/NavBox/GridContainer/Label36
@onready var across: Label = $HBoxContainer/NavBox/GridContainer/Label38

@onready var pid: Label = $HBoxContainer/NavBox/GridContainer/Label40

func _process(_delta: float) -> void:
	# References to ship and nav
	var ship: PlayerShip = ShipData.player_ship
	var nav: NavigationModule = ShipData.player_ship.navigation_module
	
	# Set time
	sclk.text = str(snapped(SimTime.t, 1))

	# Set positions
	var r: Vector3 = Conversions.position_inertial_to_body(ship.position,SimTime.t)
	rx.text = str(snapped(r.x, 1)) + "km"
	ry.text = str(snapped(r.y, 1)) + "km"
	rz.text = str(snapped(r.z, 1)) + "km"

	# Set velocities
	var v: Vector3 = Conversions.velocity_inertial_to_body(ship.velocity,SimTime.t)
	vx.text = str(snapped(v.x, 0.1)) + "km/s"
	vy.text = str(snapped(v.y, 0.1)) + "km/s"
	vz.text = str(snapped(v.z, 0.1)) + "km/s"

	# Set accelerations
	var thrust: float = ship.thrust_acceleration.length()/0.00981 # in units of G
	thr.text = str(snapped(thrust, 0.01)) + "g"
	var gravity: float = ship.gravity_acceleration.length()/0.00981 # in units of G
	g.text = str(snapped(gravity, 0.01)) + "g"

	# Set rotations
	var euler: Vector3 = ship.attitude.get_euler()
	rotx.text = str(snapped(euler.x, 0.001))
	roty.text = str(snapped(euler.y, 0.001))
	rotz.text = str(snapped(euler.z, 0.001))

	# Set waypoints
	var active: int = nav.active_waypoint
	from.text = str(active)
	to.text = str(active + 1)

	# Set progress
	prog.text = str(snapped(100*nav.t, 0.01)) + "%"

	# Set enroute times (TBD)

	# Set relative positions
	rplus.text = str(snapped(nav.remaining_distance, 1)) + "km"
	rcross.text = str(snapped(nav.p_error.length(), 1)) + "km"

	# Set relative velocities
	vplus.text = str(snapped(nav.on_course_velocity.length(), 1)) + "km/s"
	vcross.text = str(snapped(nav.d_error.length(), 0.01)) + "km/s"

	# Set commanded accelerations
	aplus.text = str(snapped(nav.a3.length()/0.00981, 0.01)) + "G"
	across.text = str(snapped(nav.a2.length()/0.00981, 0.01)) + "G"
	
	# Set PID ratios
	var p_response := (nav.Kp*nav.scalek)*nav.p_error.length()
	var i_response := (nav.Ki*nav.scalek)*nav.i_error.length()
	var d_response := (nav.Kd*nav.scalek)*nav.d_error.length()
	var p_frac := p_response/(p_response+i_response+d_response)
	var i_frac := i_response/(p_response+i_response+d_response)
	var d_frac := d_response/(p_response+i_response+d_response)
	pid.text = str(snapped(100*p_frac, 1)) + "/" + str(snapped(100*i_frac, 1)) + "/" + str(snapped(100*d_frac, 1))

func format_time(seconds: int) -> String:
	var signs := "T+"
	if seconds < 0:
		signs = "T-"
		seconds = abs(seconds)

	# Break down
	seconds = int(seconds)
	@warning_ignore("integer_division")
	var days := int(seconds / 86400)
	@warning_ignore("integer_division")
	var hours := int((seconds % 86400) / 3600)
	@warning_ignore("integer_division")
	var minutes := int((seconds % 3600) / 60)
	var secs := int(seconds % 60)

	# Cap days at 99
	if days > 99:
		return "%s99d23h59m59s" % signs

	return "%s%02dd%02dh%02dm%02ds" % [signs, days, hours, minutes, secs]
