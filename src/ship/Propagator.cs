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

	// Initialize planned lists (for trajectory planning)
	public Godot.Collections.Array<Vector3> planned_positions;
	public Godot.Collections.Array<Vector3> planned_velocities;
	public Godot.Collections.Array<double> planned_times;
	public Godot.Collections.Array<Vector3> planned_controls;

	// Initialize arrays for passing up
	public Godot.Collections.Array<Vector3> plotted_positions;
	public Godot.Collections.Array<Vector3> passed_planned_positions;

	// Initial conditions
	public Vector3 start_position;
	public Vector3 start_velocity;
	[Export]
	public int n;

	private Node OwnShip;

	public int c = 0;
	public double timescale = 0.07d;

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

	(Vector3 rp, Vector3 vp, double tp) StepVerlet(Vector3 r, Vector3 v, Vector3 c, double t)
    {
		Vector3 a = Acceleration(r,t);
        double dt = timescale/a.Length();
		dt = Math.Clamp(dt,1,100000);
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

	public void SMC(Vector3 initial_position, Vector3 target_position, Vector3 initial_velocity, double t)
	{
		// Initialize lists of size n to hold data
		planned_positions = new Godot.Collections.Array<Vector3>();
		planned_velocities = new Godot.Collections.Array<Vector3>();
		planned_times = new Godot.Collections.Array<double>();
		planned_controls = new Godot.Collections.Array<Vector3>();

		planned_times.Add(t);
		planned_positions.Add(initial_position);
		planned_velocities.Add(initial_velocity);
		planned_controls.Add(Vector3.Zero);

		Vector3 previous_distance = Vector3.Zero;
		Vector3 distance = Vector3.Zero;

		int flip = 1; // whether to burn prograde or retrograde
		int i = 0;
		bool disallow_stop = true;
		while (distance.LengthSquared() < previous_distance.LengthSquared() || disallow_stop)
		{
			// Calculate acceleration -> to counter it
			Vector3 a = Acceleration(planned_positions[i],planned_times[i]);

			// Calculate control as antigravity + in direction or opposite if more than halfway
			Vector3 flight_direction = target_position - initial_position;
			planned_controls.Add(flip*0.05d*flight_direction.Normalized() - a);
			
			// Propagate to next timestep
			(Vector3 np,Vector3 nv,double nt) = StepVerlet(planned_positions[i],planned_velocities[i],planned_controls[i],planned_times[i]);
			planned_times.Add(nt);
			planned_positions.Add(np);
			planned_velocities.Add(nv);

			// End if near target
			previous_distance = distance;
			distance = target_position - planned_positions[i+1];

			if (distance.Length() < flight_direction.Length()*0.5d)
			{
				flip = -1;
			}
			if (disallow_stop)
			{
				if (distance.LengthSquared() < previous_distance.LengthSquared())
				{
					disallow_stop = false;
				}
			}
			if (i > 1000)
			{
				break;
			}
			i++;
		}

		planned_controls.Add(new Vector3(0d,0d,0d));

		Godot.Collections.Array<Vector3> converted_planned_positions = Conversions.Instance.SubtractBodyMotion(planned_positions, planned_times);
		passed_planned_positions = new Godot.Collections.Array<Vector3>(converted_planned_positions);
	}

	public void ClearPlan()
	{
		passed_planned_positions = null;
	}
}
