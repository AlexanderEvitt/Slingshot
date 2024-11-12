using Godot;
using System;
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
			f = 1;
		}
	}

	public List<Vector3> SubtractBodyMotion(List<Vector3> positions, List<double> times)
	{
		// Place the positions into the frame listed
		List<Vector3> new_positions = new List<Vector3> ( new Vector3[positions.Count] );
		Node body_node = bodies[f];
		planet body = (planet)body_node;
		for (int i = 0; i < positions.Count; i++)
		{
			new_positions[i] = positions[i] - body.fetch(times[i]) + body.fetch(t);
		}
		return new_positions;
	}

	public Vector3 ToUniversal(Vector3 positions)
	{
		// Convert the start position, given in relative to the start frame, to universal position
		Node body_node = bodies[f];
		planet body = (planet)body_node;
		Vector3 new_positions = positions + body.fetch(t);
		return new_positions;
	}

	public Vector3 VelToFrame(Vector3 v)
	{
		// Convert the start position, given in relative to the start frame, to universal velocity
		Node body_node = bodies[f];
		planet body = (planet)body_node;
		Vector3 vel = body.fetch(1d) - body.fetch(0d);
		Vector3 new_v = v + vel;
		return new_v;
	}
}
