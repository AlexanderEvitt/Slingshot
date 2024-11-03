using Godot;
using System;

public partial class SystemTime : Node
{
	public static SystemTime Instance { get; private set; } // time singleton

	public int t0 = 0;
	public double t { get; set; }
	public double step = 0.0f;
	public double[] steps;
	public int i = 0;


	public override void _Ready()
	{
		t = 0;
		Instance = this;

		steps = new double[] {0.0d,1.0d,10.0d,100.0d,1000.0d,10000.0d,100000.0d};
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		step = steps[i];
		t = t + step*delta;

		if (Input.IsActionJustPressed("time_speed_up"))
		{
			i = (i + 1);
		}
		else if (Input.IsActionJustPressed("time_speed_down"))
		{
			i = (i - 1);
		}
		i = Math.Clamp(i,0,steps.Length - 1);
	}
}
