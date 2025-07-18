using Godot;
using System.Collections.Generic;

public partial class Conversions : Node
{
	public static Conversions Instance { get; private set; } // conversions singleton
	int f = 3;
	double t;
	public Godot.Collections.Array<Node> bodies;
	
	public override void _Ready()
	{
		Instance = this;
		bodies = GetTree().GetNodesInGroup("Bodies");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		double t = SystemTime.Instance.t;
		if (Input.IsActionJustPressed("next_frame"))
		{
			f = (f + 1);
		}
		if (f > bodies.Count - 1)
		{
			f = 0;
		}
	}

	public Godot.Collections.Array<Vector3> SubtractBodyMotion(Godot.Collections.Array<Vector3> positions, Godot.Collections.Array<double> times)
	{
		// Place the positions into the frame listed
		// Each point is now how much the craft has moved since t0 minus how much the frame has moved since t0
		Godot.Collections.Array<Vector3> new_positions = new Godot.Collections.Array<Vector3> ( new Vector3[positions.Count] );
		Node body_node = bodies[f];
		for (int i = 0; i < positions.Count; i++)
		{
			// Subtract how much the ref body moves between the start of the array and the current time step
			new_positions[i] = positions[i] - positions[0] - (Vector3)body_node.Call("fetch",times[i]) + (Vector3)body_node.Call("fetch",times[0]);
		}
		return new_positions;
	}

	public Vector3 ToUniversal(Vector3 position, double t)
	{
		// Convert the start position, given in relative to the start frame, to universal position
		Node body_node = bodies[f];
		Vector3 new_positions = position + (Vector3)body_node.Call("fetch",t);
		return new_positions;
	}

	public Vector3 ToFrame(Vector3 position, double t)
	{
		// Convert the start position, given in relative to the start frame, to universal position
		Node body_node = bodies[f];
		Vector3 new_positions = position - (Vector3)body_node.Call("fetch",t);
		return new_positions;
	}

	public Vector3 VelFromFrame(Vector3 v, double t)
	{
		// Convert the start position, given in relative to the start frame, to universal velocity
		Node body_node = bodies[f];
		Vector3 vel = (Vector3)body_node.Call("fetch",1d+t) - (Vector3)body_node.Call("fetch",t);
		Vector3 new_v = v + vel;
		return new_v;
	}

	public Vector3 VelToFrame(Vector3 v, double t)
	{
		// Convert a universal velocity to a frame velocity
		// Only works at initial timestep
		Node body_node = bodies[f];
		Vector3 vel = (Vector3)body_node.Call("fetch",1d+t) - (Vector3)body_node.Call("fetch",t);
		Vector3 new_v = v - vel;
		return new_v;
	}

	public Vector3 FindFrame(double t)
	{
		// Returns position of current frame origin
		Node frame_body = bodies[f];
		return (Vector3)frame_body.Call("fetch", t);
	}

	public Vector3 CalcEccentricity(Vector3 r, Vector3 v, double t)
	{
		// Calculates the eccentricity vector
		// Get the planet's mu
		Node body_node = bodies[f];
		double mu = (double)body_node.Get("GM");

		Vector3 r_frame = ToFrame(r,t);
		Vector3 v_frame = VelToFrame(v,t);

		Vector3 h_frame = r_frame.Cross(v_frame);
		Vector3 e = (1/mu)*(v_frame.Cross(h_frame) - mu*r_frame/r_frame.Length());

		return e;
	}

	public double CalcExcess(Vector3 r, Vector3 v, double t)
	{
		// Calculates the hyperbolic excess velocity
		// Get the planet's mu
		Node body_node = bodies[f];
		double mu = (double)body_node.Get("GM");

		Vector3 r_frame = ToFrame(r,t);
		Vector3 v_frame = VelToFrame(v,t);

		double v_esc = (double)Mathf.Sqrt(2f*mu/r_frame.Length());
		double v_exc = v_frame.Length() - v_esc;

		return v_exc;
	}
}
