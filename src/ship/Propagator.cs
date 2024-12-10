using Godot;
using Godot.Collections;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class Propagator : Node3D
{
	// Initialize times, positions, velocities, and controls arrays
	public Godot.Collections.Array<Node> bodies;
	public List<Vector3> positions;
	public List<Vector3> velocities;
	public List<double> times;
	public List<Vector3> controls;

	public Godot.Collections.Array<Vector3> plotted_positions;

	// Initial conditions
	public Vector3 start_position;
	public Vector3 start_velocity;
	[Export]
	public int n;

	private Node OwnShip;

	public int c = 0;
	public double timescale = 0.01d;

	public override void _Ready()
	{
		// Get planets
		bodies = GetTree().GetNodesInGroup("Bodies");

		// Get singleton for OwnShip (written in GDScript so this is necessary)
		OwnShip = GetNode("/root/OwnShip");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		
		if (c == 0)
		{
			// Reset starting point to current point
			start_position = (Vector3)OwnShip.Get("position");
			start_velocity = (Vector3)OwnShip.Get("velocity");

			// Refresh trajectory
			double t = SystemTime.Instance.t;
			Refresh(t);
			c = 30;
			
		}
		c = c - 1;

		// expose positions for plotting
		List<Vector3> converted_positions = Conversions.Instance.SubtractBodyMotion(positions, times);
		plotted_positions = new Godot.Collections.Array<Vector3>(converted_positions);
	}

	public Vector3 Acceleration(Vector3 r, double t)
	{
		Vector3 a = new Vector3(0d,0d,0d);
		foreach (Node body in bodies)
		{
			planet p = (planet)body;
			Vector3 r_to = r - p.fetch(t);
			double sqrDist = r_to.LengthSquared();
            a = a - r_to.Normalized() * (p.GM / sqrDist);
		}
		return a;
	}

	(Vector3 rp, Vector3 vp, double tp) StepTCV(Vector3 r, Vector3 v, double t, double tm)
    {
        Vector3 a = Acceleration(r,t);
        double dt = timescale/a.Length();
		double tp = t + dt;
		Vector3 rp = r + v*dt + 0.5d*a*Math.Pow(dt,2d);
		Vector3 vp = v + 0.5d*(a+Acceleration(rp,tp))*Math.Pow(dt,2d);
		return (rp,vp,tp);
    }

	(Vector3 rp, Vector3 vp, double tp) StepVerlet(Vector3 r, Vector3 v, double t)
    {
		Vector3 a = Acceleration(r,t);
        double dt = timescale/a.Length();
		dt = Math.Clamp(dt,1,100000);
		double tp = t + dt;
		Vector3 rp = r + v*dt + 0.5d*a*Math.Pow(dt,2d);
		Vector3 vp = v + 0.5d*(a+Acceleration(rp,tp))*dt;
		return (rp,vp,tp);
    }

	public void Refresh(double t)
	{
		// Initialize lists of size n to hold data
		positions = new List<Vector3> ( new Vector3[n] );
		velocities = new List<Vector3> ( new Vector3[n] );
		times = new List<double> ( new double[n] );

		times[0] = t;
		positions[0] = start_position;
		velocities[0] = start_velocity;

		// Step through every index to fill data
		for (int i = 0; i < n-1; i++)
		{
			(positions[i+1],velocities[i+1],times[i+1]) = StepVerlet(positions[i],velocities[i],times[i]);
		}
	}
}
