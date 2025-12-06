extends Node

# Fuel quantity (kg)
var he_quant = 0.04*4443984
var de_quant = 0.04*2962656
var hyd_quant = 0.08*13985432


# Total thrust applied to vehicle, including thrusters
var thrust = Vector3(0,0,0) # in ship frame
# Actual thrust from main engine only
var main_thrust = 0.0
# Maneuvering thrusters acceleration
var thruster_force = 1e6 # N
# Maximum allowable engine acceleration
var engine_power = 10000.0*0.05 # km/s2

# Desired acceleration (km/s2)
var throttle = 0.0

# Constants
var fusion_energy_density = 3.5897e14 # J/kg

# Design parameters
var design_power = 5.0e+13 # W

# Reactor power simulation state variables
var power = 0.0
var power_dot = 0.0
var power_ddot = 0.0
var beta = 1.0
var k = 100.0 # proportional constant
var c = 50.0 # damping constant
var exhaust_velocity = 0.0 # exhaust velocity
var power_limit = 120.0e12 # W

# Mass flow total and through each pump
var reactor_mass_flow = 0.0
var reactor_mass_flow_he = 0.0
var reactor_mass_flow_de = 0.0
var propulsor_mass_flow = 0.0 # hydrogen flow

# Pump flow control variables
var kp = 1e-8

# Required electrical power
var electrical_power = 1e13 # W

# State of control system
var propulsor := false
var reactor := false
var cryo := false
var field := false
var thrust_limiter := true
var scram_inhibit := true

# Magnet fields and temps
var fields = [0,0,0,0,0,0]
var start_temp = 300.0
var thermal_mass = 1000.0
var transfer_coefficient = 200.0
var coolant_temp = 15 # K
var temps = [start_temp,start_temp,start_temp,start_temp,start_temp,start_temp]

@onready var ship = get_parent()

func update(dt: float) -> void:
	thrust = Vector3(0,0,0)
	
	# Input main engine commanded throttle
	if Input.is_action_pressed("increment_throttle"):
		throttle = throttle + 0.001
	if Input.is_action_pressed("decrement_throttle"):
		throttle = throttle - 0.001
	if ship.avionics["navigation"] and ship.avionics["autopilot"]:
		throttle = ship.navigation_calculator.control_throttle
	throttle = clamp(throttle,0,engine_power)
	
	# Get desired engine parameters
	var mass = ship.total_mass
	var desired_thrust = mass*1000*throttle # (kg)*(km/s) -> N
	
	# Simulate engine if time rate is 1

	# Simulate FRC power
	# Get desired thrust power (linear for now)
	var thrust_power = design_power*sqrt(throttle/0.01)
	if thrust_limiter:
		thrust_power = clamp(thrust_power, 0.0, power_limit)
	# Add electrical power to thrust power to get steady state power output
	var steady_power = 0.0
	var frac_elec = 1.0
	if reactor:
		steady_power = thrust_power + electrical_power
		frac_elec = electrical_power/steady_power # fraction of total power not in thrust
	
	# Damping decreases with power using stability beta
	# Loses 90% of its damping by reaching the power limit
	beta = 1.0 - 0.9*(power/power_limit)
	var c_current = beta*c
	
	# Simulate spring mass damper for instantaneous power of reactor
	# only if in real time
	if SystemTime.step == 1:
		var power_err = power - steady_power
		power_ddot = -k*power_err - c_current*power_dot
		power_dot = power_dot + power_ddot*dt
		power = power + power_dot*dt
	# otherwise assume steady flow
	else:
		# Turn on thrust limiting if not enabled
		thrust_limiter = true
		power = steady_power
	# Clamp power to reasonable limits
	power = clamp(power, 0.0, 1000.0*design_power)

	# Get reactor mass flow from power
	reactor_mass_flow = steady_power/fusion_energy_density # kg/s
	
	# If chilling, ensure something is always flowing through core
	if cryo:
		reactor_mass_flow = clamp(reactor_mass_flow, 0.05, 1e99)
	
	# Calculate thrust from power and flow rate
	exhaust_velocity = 0.0 # m/s
	thrust_power = (1.0 - frac_elec)*power # unsteady thrust power
	if (propulsor_mass_flow +  reactor_mass_flow) != 0.0:
		exhaust_velocity = sqrt(2*thrust_power/(propulsor_mass_flow + reactor_mass_flow)) # m/s
	main_thrust = (propulsor_mass_flow + reactor_mass_flow)*exhaust_velocity
	thrust = thrust + Vector3(main_thrust,0,0) # N
	
	# Control propulsor mass flow with a proportional control on thrust
	# Get control signal for propulsor pumps
	var thrust_err = thrust.length() - desired_thrust
	# Change mass flow by thrust error, only if propulsor enabled
	if propulsor:
		propulsor_mass_flow = propulsor_mass_flow - kp*thrust_err
		# Ensure value doesn't become physically impossible
		propulsor_mass_flow = clamp(propulsor_mass_flow,0.0,1e6)
	else:
		propulsor_mass_flow = 0.0
	
	# Split mass flow by fuel and destination
	reactor_mass_flow_he = reactor_mass_flow*(3.0/5.0) # all helium mass flow
	reactor_mass_flow_de = reactor_mass_flow*(2.0/5.0) # all deuterium mass flow
		
	# Remove fuel from tanks
	he_quant = he_quant - reactor_mass_flow_he*dt
	de_quant = de_quant - reactor_mass_flow_de*dt
	hyd_quant = hyd_quant - propulsor_mass_flow*dt
	
	# Calculate magnetic temperatures
	# Loop through each magnet
	for i in 6:
		var absorbed_power_fraction = randf()*1e-10
		var effective_mass_flow = exp(-power/power_limit)*reactor_mass_flow
		# Calculate power of heating from reactor
		var heating = absorbed_power_fraction*power
		var cooling = effective_mass_flow*transfer_coefficient*(temps[i] - coolant_temp)
		var Q = heating - cooling
		temps[i] = temps[i] + (1/thermal_mass)*Q*dt
		if temps[i] < 0.0:
			temps[i] = 0.0
	
	# Print diagnostic information
	if false:
		print("Requesting acceleration: ", throttle)
		print("	Thrust/desired: ", thrust.length()/desired_thrust)
		print("	Power frac: ", power/design_power)
		print(" Temp: ", temps[0])
		

	
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
