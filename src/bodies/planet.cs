using Godot;
using System;
using System.Text;
using NaifSpiceSharp;
using System.Linq;



public partial class planet : Node3D
{
	public double t;
	[Export]
	public string body;
	[Export]
	public double GM;
	double scaledown = 1e3d;


	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		// Must be unsafe as SPICE functions take in pointers
		unsafe 
		{

			// Initialize SPICE kernel
			string metaFilePath = System.Environment.ExpandEnvironmentVariables(@"%appdata%\SPICE\de440.bsp");
			fixed (byte* pathChars = Encoding.ASCII.GetBytes(metaFilePath))
			{
				Spice.FURNSH_C(pathChars);
			}
			
			// Furnish leap second kernel
			var LSKFilePath = System.Environment.ExpandEnvironmentVariables(@"%appdata%\SPICE\naif0012.tls");
			fixed (byte* pathChars = Encoding.ASCII.GetBytes(LSKFilePath))
			{
				Spice.FURNSH_C(pathChars);
			}

			// Get initial ephemeris time
			double tdb;
			fixed (byte* timeChars = Encoding.ASCII.GetBytes("2024 OCTOBER 29 23:59:59.9"))
			{
				Spice.STR2ET_C(timeChars, &tdb);
			}
			t = 0;
		}
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		t = SystemTime.Instance.t;
		Position = fetch(t)/1000d;
	}

	public Vector3 fetch(double time)
	{
		unsafe
		{
			// Calc position and velocity
			//time = time + t; // make times relative to starting time
			double* state = stackalloc double[6]; // (x, y, z, vx, vy, vz)
			for (int i = 0; i < 6; i++)
			{
				state[i] = 0;
			}
			double lt = 0; // Light time
			fixed (byte* target = Encoding.ASCII.GetBytes(body))
			fixed (byte* obs = Encoding.ASCII.GetBytes("SOLAR SYSTEM BARYCENTER"))
			fixed (byte* frame = Encoding.ASCII.GetBytes("J2000"))
			fixed (byte* corr = Encoding.ASCII.GetBytes("NONE"))
			{
				Spice.SPKPOS_C(target, time, frame, corr, obs, state, &lt);
			}
			
			var pos = new Vector3(state[0],state[1],state[2]);
			return pos;
		}
	}
}
