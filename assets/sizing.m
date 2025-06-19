%% Sizing for interplanetary spacecraft
clear; close all; clc;

% Energy density of fusion fuels, He3 + D, J/kg
E = (19e6*365*24*60*60)/1.67;

% Theoretical upper limit on exhaust velocity
v = sqrt(2*E);
% Efficiency of system
eff = 0.95;
v = eff*v;

% Mass fraction, fueled mass over empty mass
mf = 2;
% Total delta-V, m/s
dV = v*log(mf);

% Time of flight at given acceleration
a = 10  * 9.81;
tb = dV/a;
tb = tb/(60*60*24) % in days

% Time of flight of theoretical flip-and-burn trip
r = 20 * 1.496e11; % 1 au, m
tf = 2*sqrt(r/a);

tf = tf/(60*60*24) % in days

% Gravity of the sun at the radius
as = 1.327e20/(r^2);


%% Sizing for tanks
% Mass of ship
m = 1000*(108*27*25.4)*0.3;

% Mass of fuel
m_fuel = m*(mf - 1)/mf;

% Fuel fraction
f_mass_fraction = 3/5;
m_helium = f_mass_fraction*m_fuel;
m_deuterium = (1-f_mass_fraction)*m_fuel;

% Volumes
v_helium = m_helium/146.2; %https://www.engineeringtoolbox.com/helium-density-specific-weight-temperature-pressure-d_2090.html
v_deuterium = m_deuterium/76.91; %https://www.engineeringtoolbox.com/hydrogen-H2-density-specific-weight-temperature-pressure-d_2044.html

inv(v_helium/v_deuterium)

% Tank volume
r = 10; % m
h = 30; % m
v_tank = pi*(r^2)*h + (4/3)*pi*r^3;
v_tank/v_deuterium

%% Brightness and thermals
percent_emmitted = 0.05;
wattage = percent_emmitted*E*m_fuel / tb;
dist = 74000000;
flux = wattage/(4*pi*dist^2);
flux/1400 % in percent of solar irradiance at 1AU

%% Centrifugal ring sizing
clear; clc;
w = 0.04; % rad /s
r = 4500;
a = (w^2)*r

rpm = (w/(2*pi))*(60)
hpr = (1/rpm)/60
