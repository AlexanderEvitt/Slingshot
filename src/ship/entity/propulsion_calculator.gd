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

# Constants
var fusion_energy_density = 3.5897e14 # J/kg

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

# Mass flow total and through each pump
var reactor_mass_flow = 0.0
var reactor_mass_flow_he = 0.0
var reactor_mass_flow_de = 0.0
var propulsor_mass_flow = 0.0 # hydrogen flow

# Pump flow control variables
var kp = 1e-9

# Required electrical power
var electrical_power = 2e14 # W

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
		# Simulate FRC power
		# Get desired thrust power (linear for now)
		var thrust_power = 0.5*design_power*(throttle/0.01)
		thrust_power = clamp(thrust_power, 0e15, 3e15)
		# Add electrical power to thrust power to get steady state power output
		var steady_power = thrust_power + electrical_power
		var frac_elec = electrical_power/steady_power # fraction of total power not in thrust
		
		# Simulate spring mass damper for instantaneous power of reactor
		var power_err = power - steady_power
		power_ddot = -k*power_err - c*power_dot
		power_dot = power_dot + power_ddot*dt
		power = power + power_dot*dt
		power = clamp(power, 0.0, 100.0*design_power)

		# Get reactor mass flow from power
		reactor_mass_flow = power/fusion_energy_density # kg/s
		
		# Calculate thrust from power and flow rate
		exhaust_velocity = 0.0 # m/s
		thrust_power = (1.0 - frac_elec)*power # unsteady thrust power
		if propulsor_mass_flow != 0.0:
			exhaust_velocity = sqrt(2*thrust_power/(propulsor_mass_flow + reactor_mass_flow)) # m/s
		main_thrust = (propulsor_mass_flow + reactor_mass_flow)*exhaust_velocity
		thrust = thrust + Vector3(main_thrust,0,0) # N
		
		# Control propulsor mass flow with a proportional control on thrust
		# Get control signal for propulsor pumps
		var thrust_err = thrust.length() - desired_thrust
		# Change mass flow by thrust error
		propulsor_mass_flow = propulsor_mass_flow - kp*thrust_err
		# Ensure value doesn't become physically impossible
		propulsor_mass_flow = clamp(propulsor_mass_flow,0.0,100.0*design_mass_flow)
		
		# Split mass flow by fuel and destination
		reactor_mass_flow_he = reactor_mass_flow*(3.0/5.0) # all helium mass flow
		reactor_mass_flow_de = reactor_mass_flow*(2.0/5.0) # all deuterium mass flow
		
	else:
		# At other time rates, don't control, just set the values
		# Should you not be allowed to time warp above design thrust?
		thrust = thrust + Vector3(desired_thrust,0,0)
		exhaust_velocity = 1.0526*design_ve
		reactor_mass_flow = desired_thrust/exhaust_velocity
		power = 0.5*reactor_mass_flow*pow(exhaust_velocity,2)
		power_dot = 0.0
		power_ddot = 0.0
		
	# Remove fuel from tanks
	he_quant = he_quant - reactor_mass_flow_he*dt
	de_quant = de_quant - reactor_mass_flow_de*dt
	
	# Print diagnostic information
	if false:
		print("Requesting acceleration: ", throttle)
		print("	Thrust: ", thrust)
		print("	Desired_thrust: ", desired_thrust)
		print("	Reactor mass flow frac: ", reactor_mass_flow/design_mass_flow)
		print("	Propulsor mass flow frac: ", propulsor_mass_flow/design_mass_flow)
		print("	Efficiency: ", exhaust_velocity/design_ve)
		print("	Power frac: ", power/design_power)
		print("	Produced energy density: ", power/reactor_mass_flow)

	
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
