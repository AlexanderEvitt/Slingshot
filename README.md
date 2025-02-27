# Slingshot
## Astrodynamics Simulator

![Flying Past Stars](streaks.png)
![Logo](src/visuals/logo/wide.png)

Slingshot is a full-up, 6DOF astrodynamics simulation with a cool UI. Aimed at being somewhere between a video game and a display for flight operations teams, it presents a complete sandbox for spacecraft navigation and control.

Demo footage: [YouTube Link](https://youtu.be/0PLd5gBSCrM)

![Ejecting from Earth, Looking Back](looking_back.png)
![Planning a Luna Transfer](planning.png)
![Burning Hard for Ejection](burning_hard.png)
![Interplanetary Transfer](transfer.png)
![Arrival in Luna Orbit](luna_orbit.png)


## Current Features

- Full solar system of planets with data taken from SPICE
- n-body physics providing a numerically-integrated trajectory (with symplectic integrators and adaptive step size control)
- Flight instruments to allow "eyeballing" trajectories, allowing the user to get familiar with n-body motion
- Autopilot capable of plotting "flip-and-burn" trajectories between planets
- Cool graphics that belong on the big screen in a control room

## Planned Features

- More minor solar system bodies, moons, asteroids, etc
- More autopilot algorithms to assist in trajectory creation
- Numerical trajectory optimizaiton algorithms
- Full rendezvous and docking simulation
- Power and propulsion simulation
- 2D plots to aid trajectory design
- Visual additions - Lagrange points, manifolds, gravitational potential plots, and more

## Dev Environment Setup Instructions

1. Clone the repo somewhere safe
2. Download the SPICE data required, place it at /AppData/Roaming/SPICE/ (currently only works on Windows)
3. Download the .NET library 8.0
4. Configure NuGet to use the local source stored in the repo at /editor/MyLocalNugetSource/
```
dotnet nuget add source <repo_location/editor/MyLocalNugetSource> --name MyLocalNugetSource
```
5. Clear the NuGet cache
```
dotnet nuget locals --clear all
```