# Slingshot
## Astrodynamics Simulator

![Cover](cover.png)
![Flying Past Stars](streaks.png)

Slingshot is a 6DOF spaceflight simulator that combines futuristic high-energy fusion propulsion systems with realistic physics. The entire solar system is implemented at real scale.

Demo footage: [YouTube Link](https://youtu.be/2RoTKBjrhYA?si=A5Ma15xtFgd1WDBr)

![Entering the Jupiter System](planning.png)
![Departing from Zephyr Station](proxops.png)


## Current Features

- Full solar system of planets and significant moons
- Network of space stations for docking and undocking
- n-body physics providing a numerically-integrated trajectory (with symplectic integrators and adaptive step size control)
- Guidance computer that provides autopilot functionality for interplanetary trips
- Translation and docking simulation
- Cool graphics

## Development Plan

- (CURRENT) v0.0.1: Interplanetary transport game mode - fly between stations scattered around the solar system to complete missions.
- v0.0.2: Space combat - defend your ship from pirates and hostile adversaries as you fly around.
- v0.0.3: Extrasolar flight - addition of other solar systems beyond Sol.
- v0.0.4: Ship interiors - addition of ship interior.
- v0.0.5: More pilotable ship types

## Dev Environment Setup Instructions

1. Clone the repo somewhere safe
3. Download the .NET library 8.0
4. Configure NuGet to use the local source stored in the repo at /editor/MyLocalNugetSource/
```
dotnet nuget add source <repo_location/editor/MyLocalNugetSource> --name MyLocalNugetSource
```
5. Clear the NuGet cache
```
dotnet nuget locals --clear all
```
