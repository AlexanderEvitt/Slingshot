using Godot;
using System;

public partial class Body : Node3D
{
    private Node3D parentBody;

    // Values used by children
    [Export]
    public double GM { get; set; } // km^3/s^2

    // Input orbital elements
    [Export]
    public double a { get; set; } = 384000.0; // semi-major axis, km
    [Export]
    public double e { get; set; } = 0.0;      // eccentricity
    [Export]
    public double i { get; set; } = 0.0;      // inclination, rad
    [Export]
    public double RAAN { get; set; }           // right ascension, rad
    [Export]
    public double argp { get; set; }           // argument of periapsis, rad
    [Export]
    public double theta0 { get; set; }         // initial true anomaly

    // Persistent values for orbital calculations
    private double M;               // mean anomaly
    private double period;               // orbital period
    private double p;               // semi-latus rectum
    private double sqrtMuOverP;
    private double c1, c2, c3, c4, c5, c6;

    private Basis Ri;
    private Basis Rom;
    private Basis Rcombine;

    public override void _Ready()
    {
        parentBody = GetParent<Node3D>();
        double parentMu = (double)parentBody.Get("GM");

        // Orbital constants
        M = 0.0;
        period = 2.0 * Math.PI * Math.Sqrt(Math.Pow(a, 3.0) / parentMu);
        p = a * (1.0 - Math.Pow(e, 2.0));
        sqrtMuOverP = Math.Sqrt(parentMu / p);

        // Coefficients for true anomaly approximation
        c1 = 2.0 * e - 0.25 * Math.Pow(e, 3.0) + (5.0 / 96.0) * Math.Pow(e, 5.0);
        c2 = (5.0 / 4.0) * Math.Pow(e, 2.0) - (11.0 / 24.0) * Math.Pow(e, 4.0) + (17.0 / 192.0) * Math.Pow(e, 6.0);
        c3 = (13.0 / 12.0) * Math.Pow(e, 3.0) - (43.0 / 64.0) * Math.Pow(e, 5.0);
        c4 = (103.0 / 96.0) * Math.Pow(e, 4.0) - (451.0 / 480.0) * Math.Pow(e, 6.0);
        c5 = (1097.0 / 960.0) * Math.Pow(e, 5.0);
        c6 = (1223.0 / 960.0) * Math.Pow(e, 6.0);

        // Rotation matrices
        Ri = Basis.Identity.Rotated(new Godot.Vector3(1, 0, 0), (double)i);
        Rom = Basis.Identity.Rotated(new Godot.Vector3(0, 0, 1), RAAN);

        Rcombine = Rom * Ri;

        // Produce the orbital period so orbit plotters can use it
    }

    public override void _PhysicsProcess(double delta)
    {
        // Set the position of the body
        Position = get_local_position(SystemTime.Instance.t);
    }

    public Godot.Vector3 fetch(double time)
    {
        // Return the position of the body in the solar system's frame
        return (Godot.Vector3)parentBody.Call("fetch", time) + get_local_position(time);
    }

    public Godot.Vector3 fetch_velocity(double time)
    {
        // Does a finite difference approximation
        // Very low confidence in get_local_velocity due to the approximation of true anomaly right now
        // So using this for the moment
        float dt = 0.01f;
        return (Godot.Vector3)((fetch(SystemTime.Instance.t) - fetch(SystemTime.Instance.t - dt))/dt);
    }

    private Godot.Vector3 get_local_position(double time)
    {
        // Mean anomaly
        M = 2.0 * Math.PI * (time / period);

        // Approximate true anomaly
        double theta = theta0 + M
            + c1 * Math.Sin(M)
            + c2 * Math.Sin(2 * M)
            + c3 * Math.Sin(3 * M)
            + c4 * Math.Sin(4 * M)
            + c5 * Math.Sin(5 * M)
            + c6 * Math.Sin(6 * M);

        // Radius
        double r = p / (1.0 + e * Math.Cos(theta));

        // Position in orbital plane
        Godot.Vector3 rthw = new Godot.Vector3(
            (double)(r * Math.Cos(theta + argp)),
            (double)(r * Math.Sin(theta + argp)),
            0d
        );

        // Rotate into inertial space
        Godot.Vector3 pos = Rcombine * rthw;
        return pos;
    }

    private Godot.Vector3 get_local_velocity(double time)
    {
        // Not confident this actually works when using an approximation of the true anomaly.
        // Produces a different result to fetch(t) - fetch(t - 1)

        // Mean anomaly
        M = 2.0 * Math.PI * (time / period);

        // Approximate true anomaly
        double theta = theta0 + M
            + c1 * Math.Sin(M)
            + c2 * Math.Sin(2 * M)
            + c3 * Math.Sin(3 * M)
            + c4 * Math.Sin(4 * M)
            + c5 * Math.Sin(5 * M)
            + c6 * Math.Sin(6 * M);

        // Orbit parameters
        double r = p / (1.0 + e * Math.Cos(theta));
        double vr = sqrtMuOverP * e * Math.Sin(theta);
        double vt = sqrtMuOverP * (1.0 + e * Math.Cos(theta));

        // Velocity components in orbital plane (perifocal frame)
        Godot.Vector3 vthw = new Godot.Vector3(
            (double)(vr * Math.Cos(theta + argp) - vt * Math.Sin(theta + argp)),
            (double)(vr * Math.Sin(theta + argp) + vt * Math.Cos(theta + argp)),
            0d
        );

        // Rotate into inertial space with the same combined rotation as position
        Godot.Vector3 vel = Rcombine * vthw;

        return vel;
    }


}
