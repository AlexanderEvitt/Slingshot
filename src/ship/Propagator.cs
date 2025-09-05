using Godot;
using Godot.Collections;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

public partial class Propagator : Node3D
{
	// Initialize times, positions, velocities, and controls lists
	public Godot.Collections.Array<Node> bodies;
	public Godot.Collections.Array<Vector3> positions;
	public Godot.Collections.Array<Vector3> velocities;
	public Godot.Collections.Array<double> times;
	public Godot.Collections.Array<Vector3> controls;

	// Initialize arrays for passing up
	public Godot.Collections.Array<Vector3> plotted_positions;

	// Initial conditions
	public Vector3 start_position;
	public Vector3 start_velocity;
	[Export]
	public int n;

	private Node player_ship;

	public int c = 0;
	public double timescale = 0.15d;

	public override void _Ready()
	{
		// Get planets
		bodies = GetTree().GetNodesInGroup("Bodies");

		// Get singleton for ShipData (written in GDScript so this is necessary)
		player_ship = GetParent();
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		
		if (c == 0)
		{
			// Reset starting point to current point

			start_position = (Vector3)player_ship.Get("position");
			start_velocity = (Vector3)player_ship.Get("velocity");

			// Refresh trajectory
			double t = SystemTime.Instance.t;
			Refresh(t);
			c = 10;
		}
		c = c - 1;

		// expose positions for plotting
		Godot.Collections.Array<Vector3> converted_positions = Conversions.Instance.SubtractBodyMotion(positions, times);
		plotted_positions = new Godot.Collections.Array<Vector3>(converted_positions);
	}

	public Vector3 Acceleration(Vector3 r, double t)
	{
		Vector3 a = new Vector3(0d,0d,0d);
		foreach (Node body in bodies)
		{
			Vector3 r_to = r - (Vector3)body.Call("fetch",t);
			double sqrDist = r_to.LengthSquared();
            a = a - r_to.Normalized() * ((float)body.Get("GM") / sqrDist);
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

	(Vector3 rp, Vector3 vp, double tp) StepVerlet(Vector3 r, Vector3 v, Vector3 c, double t)
    {
		Vector3 a = Acceleration(r,t);
        double dt = timescale/a.Length();

		// Only allow very short times if the engine is firing
		if (c.Length() > 0d)
		{
			dt = Math.Clamp(dt,1,600);
		}
		else
		{
			dt = Math.Clamp(dt,1,100000);
		}
		
		double tp = t + dt;
		a = a + c; // add control acc
		Vector3 rp = r + v*dt + 0.5d*a*Math.Pow(dt,2d);
		Vector3 vp = v + 0.5d*(a+Acceleration(rp,tp))*dt;
		return (rp,vp,tp);
    }

	public void Refresh(double t)
	{
		// Initialize lists of size n to hold data
		positions = new Godot.Collections.Array<Vector3> ( new Vector3[n] );
		velocities = new Godot.Collections.Array<Vector3> ( new Vector3[n] );
		times = new Godot.Collections.Array<double> ( new double[n] );

		times[0] = t;
		positions[0] = start_position;
		velocities[0] = start_velocity;

		// Empty control
		Vector3 empty = new Vector3(0d,0d,0d);

		// Step through every index to fill data
		for (int i = 0; i < n-1; i++)
		{
			(positions[i+1],velocities[i+1],times[i+1]) = StepVerlet(positions[i],velocities[i],empty,times[i]);
		}
	}
}
