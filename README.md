# Slingshot
## Orbital Dynamics Solver

Slingshot aims to provide a user-friendly astrodynamics experience to those looking to design spacecraft trajectories. Currently in the early phase with basic features.

![High Orbit Around the Moon](lunar_orbit.png)
![Solar System and an Escape from Earth](solar_system.png)
![The Long Journey to Luna](enroute_to_luna.png)

## Current Features

- Full solar system of planets "on rails" - planets move in elliptical inclined orbits
- Adaptive-time Runge-Kutta4 trajectory propagation with _N_-body effects
- Basic simulation controls, including integration length and time rate
- Maneuver nodes that allow instantaneous changes in velocity
- Switching between references frames for both maneuvers and trajectory plotting
- A slick UI

## Planned Features

- Performance improvements, lots and lots of performance improvements
- More minor solar system bodies, moons, rings, etc
- Maneuver node design tools
- Maneuver node visualization
- Finally fixing the eccentricity readout
