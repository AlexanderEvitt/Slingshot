extends Node

# Fuel quantity (kg)
var he_quant = 4443984
var de_quant = 2962656


# Total thrust applied to vehicle, including thrusters
var thrust = Vector3(0,0,0) # in ship frame
# Actual thrust from main engine only
var main_thrust = 0.0
# Maneuvering thrusters acceleration
var thruster_force = 50e6 # N
# Maximum allowable engine acceleration
var engine_power = 0.05 # km/s2

# Desired acceleration (km/s2)
var throttle = 0.0

# Design parameters
var design_accel = 0.00981 # 1g
var design_power = 2.5265e+15 # W
var design_mass = 22219920 # kg
var design_fuel = 7406640 # kg
var design_ve = 2.5448e7 # m/s
var design_burn_time = 1.0518e+6 # s duration at design_power
@onready var design_mass_flow = design_fuel/design_burn_time

# Reactor power simulation state variables
var power = 0.0
var power_dot = 0.0
var power_ddot = 0.0
var k = 100.0 # proportional constant
var c = 50.0 # damping constant
var exhaust_velocity = 0.0 # exhaust velocity

# Pump flow control variables
var kp = 1e-9
var mass_flow = 0.0

# Required electrical power
var electrical_power = 1e12 # W

@onready var ship = get_parent()

func update(dt: float) -> void:
	thrust = Vector3(0,0,0)
	
	# Input main engine commanded throttle
	if Input.is_action_pressed("increment_throttle"):
		throttle = throttle + 0.001
	if Input.is_action_pressed("decrement_throttle"):
		throttle = throttle - 0.001
	if ship.nav_flag and ship.autopilot_flag:
		throttle = ship.navigation_calculator.control_throttle
	throttle = clamp(throttle,0,engine_power)
	
	# Get desired engine parameters
	var mass = ship.total_mass
	var desired_thrust = mass*1000*throttle # (kg)*(km/s) -> N
	
	# Simulate engine if time rate is 1
	if SystemTime.step == 1:
		# Get possible steady state power output of reactor
		var steady_power = (design_power/design_mass_flow)*mass_flow
		# Add electrical power to thrust power
		steady_power = steady_power + electrical_power
		
		# Simulate spring mass damper for instantaneous power of reactor
		var power_err = power - steady_power
		power_ddot = -k*power_err - c*power_dot
		power_dot = power_dot + power_ddot*dt
		power = power + power_dot*dt
		power = clamp(power, 0.0, 100.0*design_power)
		
		# Calculate thrust from power and flow rate
		exhaust_velocity = 0.0 # m/s
		if mass_flow != 0.0 and power != 0.0:
			exhaust_velocity = sqrt(2*power/mass_flow) # m/s
		main_thrust = mass_flow*exhaust_velocity
		thrust = thrust + Vector3(main_thrust,0,0) # N
		
		# Get control signal for pumps
		var thrust_err = thrust.length() - desired_thrust
		# Change mass flow by thrust error
		mass_flow = mass_flow - kp*thrust_err
		# Ensure value doesn't become physically impossible
		mass_flow = clamp(mass_flow,0.0,100.0*design_mass_flow)
		
	else:
		# At other time rates, don't control, just set the values
		# Should you not be allowed to time warp above design thrust?
		thrust = thrust + Vector3(desired_thrust,0,0)
		exhaust_velocity = 1.0526*design_ve
		mass_flow = desired_thrust/exhaust_velocity
		power = 0.5*mass_flow*pow(exhaust_velocity,2)
		power_dot = 0.0
		power_ddot = 0.0
		
	# Remove fuel from tanks
	var he_mdot = mass_flow*(3.0/5.0)
	var de_mdot = mass_flow*(2.0/5.0)
	he_quant = he_quant - he_mdot*dt
	de_quant = de_quant - de_mdot*dt
	
	# Print diagnostic information
	if false:
		print("Requesting acceleration: ", throttle)
		print("	Thrust: ", thrust)
		print("	Desired_thrust: ", desired_thrust)
		print("	Mass flow: ", mass_flow)
		print("	Efficiency: ", exhaust_velocity/design_ve)
		print("	Power frac: ", power/design_power)

	
	# Add thruster inputs to thrust
	if Input.is_action_pressed("translate_left"):
		thrust = thrust + thruster_force*Vector3(0,0,-1)
	if Input.is_action_pressed("translate_right"):
		thrust = thrust + thruster_force*Vector3(0,0,1)
	if Input.is_action_pressed("translate_up"):
		thrust = thrust + thruster_force*Vector3(0,1,0)
	if Input.is_action_pressed("translate_down"):
		thrust = thrust + thruster_force*Vector3(0,-1,0)
	if Input.is_action_pressed("translate_fore"):
		thrust = thrust + thruster_force*Vector3(1,0,0)
	if Input.is_action_pressed("translate_aft"):
		thrust = thrust + thruster_force*Vector3(-1,0,0)
