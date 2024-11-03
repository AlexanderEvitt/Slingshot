# Slingshot
## Orbital Dynamics Solver

Slingshot aims to provide a user-friendly astrodynamics UI to flight operations teams. NEW: Converted to Godot, awaiting full feature migration.

![High Orbit Around the Moon](lunar_orbit.png)
![Solar System and an Escape from Earth](solar_system.png)
![The Long Journey to Luna](enroute_to_luna.png)

## Current Features

- Full solar system of planets with data taken from SPICE
- Multiple numerical integration models, including Runge-Kutta, Forest-Ruth, and Verlet
- Pseudo-adaptive step control allows high fidelity when close to bodies and low fidelity in deep space
- Basic simulation controls, including integration length and time rate
- Maneuver nodes that allow instantaneous changes in velocity
- Switching between references frames for both maneuvers and trajectory plotting
- A slick UI

## Planned Features

- More control over the propagation algorithms
- More minor solar system bodies, moons, rings, etc
- Maneuver node design tools
- Maneuver node visualization
- Rotating reference frames
- 2D plots to aid trajectory design
- Visual additions - Lagrange points, manifolds, gravitational potential plots, and more
- Attitude control simulation
