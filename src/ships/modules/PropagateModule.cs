using Godot;
using Godot.Collections;
using System;

[GlobalClass]
public partial class PropagateModule : Node3D
{
	// Exposed to GDScript — replaced with a new object each Refresh() so the
	// Plotter's is_same() check detects that the trajectory has been updated.
	public Array<Vector3> plotted_positions;

	// Returned when the ship is berthed — allocated once at startup so no
	// per-frame allocation occurs while docked.
	private static readonly Array<Vector3> _emptyPositions = new();

	// Work arrays pre-allocated in _Ready() and overwritten in-place each
	// Refresh(), eliminating the three per-cycle allocations that previously
	// drove .NET GC pauses visible as regular process-time spikes.
	private Array<Vector3> _positions;
	private Array<Vector3> _velocities;
	private Array<double>  _times;

	private Array<Node> _bodies;

	public Vector3 start_position;
	public Vector3 start_velocity;
	[Export]
	public int n;

	private Node _playerShip;
	public int c = 0;
	public double timescale = 0.15d;

	public Node primary;

	public Node SimTime;
	public Node Conversions;
	public Node ShipData;

	// Cached frame body node — resolved once in _Ready() so BuildPlottedPositions()
	// never calls GetNode() per refresh cycle.
	private Node _frameBody;

	public override void _Ready()
	{
		SimTime    = GetNode<Node>("/root/SimTime");
		Conversions = GetNode<Node>("/root/Conversions");
		ShipData   = GetNode<Node>("/root/ShipData");

		_bodies    = GetTree().GetNodesInGroup("Bodies");
		_playerShip = GetParent();

		Node simRoot = (Node)ShipData.Get("sim_root");
		primary = simRoot.GetNode("SolarSystem");

		// Cache the reference frame body for BuildPlottedPositions() so it never
		// goes through GetNode() or a dynamic Conversions.Call() per refresh.
		// Reconnect whenever the player changes the reference frame at runtime.
		string frameName = (string)Conversions.Get("frame_name");
		_frameBody = simRoot.GetNode(frameName);
		Conversions.Connect("frame_changed", Callable.From(RefreshFrameBody));

		// Pre-allocate work arrays — Refresh() writes into existing slots so no
		// heap allocation occurs during normal flight.
		_positions  = new Array<Vector3>(new Vector3[n]);
		_velocities = new Array<Vector3>(new Vector3[n]);
		_times      = new Array<double>(new double[n]);

		plotted_positions = _emptyPositions;
	}

	public override void _Process(double delta)
	{
		if ((bool)_playerShip.Get("berthed") == false)
		{
			if (c == 0 && n != 0)
			{
				start_position = (Vector3)_playerShip.Get("system_position");
				start_velocity = (Vector3)_playerShip.Get("system_velocity");

				double t = (double)SimTime.Get("t");
				Refresh(t);
				c = 10;

				// Publish a new array object so the Plotter's is_same() check
				// detects that the trajectory has changed this cycle.
				plotted_positions = BuildPlottedPositions();
			}
			c -= 1;
		}
		else
		{
			// Assign the static empty sentinel — no allocation, and is_same()
			// returns true on subsequent berthed frames so the Plotter won't redraw.
			plotted_positions = _emptyPositions;
		}
	}

	private void RefreshFrameBody()
	{
		Node simRoot = (Node)ShipData.Get("sim_root");
		string frameName = (string)Conversions.Get("frame_name");
		_frameBody = simRoot.GetNode(frameName);
	}

	public Vector3 Acceleration(Vector3 r, double t)
	{
		Vector3 a = Vector3.Zero;
		foreach (Node body in _bodies)
		{
			Vector3 rTo    = r - (Vector3)body.Call("fetch", t);
			double sqrDist = rTo.LengthSquared();
			a -= rTo.Normalized() * ((double)body.Get("GM") / sqrDist);
		}
		return a;
	}

	private (Vector3 rp, Vector3 vp, double tp) StepVerlet(
		Vector3 r, Vector3 v, Vector3 controlAccel, double t)
	{
		Vector3 a  = Acceleration(r, t);
		double  dt = timescale / a.Length();

		// Clamp step size — shorter limit when the engine is firing so the
		// thrust direction is resolved accurately.
		dt = controlAccel.Length() > 0.0
			? Math.Clamp(dt, 1, 600)
			: Math.Clamp(dt, 1, 100000);

		double tp = t + dt;
		a += controlAccel;
		Vector3 rp = r + v * dt + 0.5 * a * (dt * dt);
		Vector3 vp = v + 0.5 * (a + Acceleration(rp, tp)) * dt;
		return (rp, vp, tp);
	}

	public void Refresh(double t)
	{
		_times[0]      = t;
		_positions[0]  = start_position;
		_velocities[0] = start_velocity;

		for (int i = 0; i < n - 1; i++)
		{
			(_positions[i + 1], _velocities[i + 1], _times[i + 1]) =
				StepVerlet(_positions[i], _velocities[i], Vector3.Zero, _times[i]);
		}
	}

	// Replicates inertial_to_ship_frame() from conversions.gd in C#, using the
	// cached _frameBody reference to avoid a GDScript boundary crossing and
	// repeated get_node() calls.
	// Formula: result[i] = positions[i] - positions[0] - (body(t[i]) - body(t[0]))
	private Array<Vector3> BuildPlottedPositions()
	{
		var result = new Array<Vector3>(new Vector3[n]);
		Vector3 bodyAt0 = (Vector3)_frameBody.Call("fetch", _times[0]);
		Vector3 pos0    = _positions[0];

		for (int i = 0; i < n; i++)
		{
			Vector3 bodyAtI = (Vector3)_frameBody.Call("fetch", _times[i]);
			result[i] = _positions[i] - pos0 - bodyAtI + bodyAt0;
		}
		return result;
	}
}
