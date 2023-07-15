using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Propagator : MonoBehaviour
{
    public Rigidbody Spacecraft;
    public Rigidbody Moon;
    private LineRenderer lr;
    float M = 1f;
    float m = 0.012345f;
    public Vector3 start_vel = Vector3.forward;
    Vector3[] positions = new Vector3[Universe.iteration_length];
    Vector3[] velocities = new Vector3[Universe.iteration_length];
    public int t = 1;
    int trailer = 0;
    public int skip = 1;
    public Vector3 velocity;

    // Start is called before the first frame update
    void Start()
    {
        positions[0] = Spacecraft.position;
        velocities[0] = start_vel;
        lr = GetComponent<LineRenderer>();
        lr.positionCount = Universe.iteration_length;
        lr.SetPosition(0, positions[0]);


        for (int i = 1; i < Universe.iteration_length; i++)
        {

            (Vector3 dv, Vector3 dr) = RungeKutta4(i - 1);
            velocities[i] = velocities[i-1] + dv;
            positions[i] = positions[i-1] + dr;

            lr.SetPosition(i, positions[i]);
        } 
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown("."))
        {
            skip = skip + 1;
        }
        if (Input.GetKeyDown(","))
        {
            skip = skip - 1;
            if (skip <= 0)
            {
                skip = 0;
            }
        }
        
        if (skip > 0)
        {
            Spacecraft.position = positions[t % Universe.iteration_length];
            velocity = velocities[t % Universe.iteration_length];
            Spacecraft.rotation = Quaternion.LookRotation(velocities[t % Universe.iteration_length].normalized) * Quaternion.Euler(90,0,0);
        }
        
        while (trailer <= t)
        {
            int trm = (trailer - 1) % Universe.iteration_length;
            if (trm < 0)
            {
                trm = Universe.iteration_length - 1;
            }
            int tr = (trailer) % Universe.iteration_length;

            (Vector3 dv, Vector3 dr) = RungeKutta4(trm);
            velocities[tr] = velocities[trm] + dv;
            positions[tr] = positions[trm] + dr;
            
            lr.positionCount = lr.positionCount + 1;
            lr.SetPosition(lr.positionCount - 1, positions[tr]);

            trailer = trailer + 1;
        }       

        t = t + skip;
    }

    Vector3 acceleration(Vector3 position, Vector3 moon_position)
    {
        Vector3 r_moon = position - moon_position;
        float sqrtDist = (position).sqrMagnitude;
        float sqrtDistMoon = r_moon.sqrMagnitude;
        Vector3 accel = position.normalized * (Universe.G * M / sqrtDist) + r_moon.normalized * (Universe.G * m / sqrtDistMoon);
        return accel;
    }

    (Vector3 dv, Vector3 dr) RungeKutta4(int i)
    {
        float h2 = (float)(Universe.time_step) / 2;
        float h6 = (float)(Universe.time_step) / 6;
        Vector3 moon_position = GameObject.Find("Moon").GetComponent<MoonOrbit>().moon_place(i);

        Vector3 k1v = acceleration(positions[i], moon_position);
        Vector3 k1r = velocities[i];

        Vector3 k2v = acceleration(positions[i] + k1r * h2, moon_position);
        Vector3 k2r = velocities[i] + k1v * h2;

        Vector3 k3v = acceleration(positions[i] + k2r * h2, moon_position);
        Vector3 k3r = velocities[i] + k2v * h2;

        Vector3 k4v = acceleration(positions[i] + k3r * Universe.time_step, moon_position);
        Vector3 k4r = velocities[i] + k3v * Universe.time_step;

        Vector3 dv = h6 * (k1v + 2 * k2v + 2 * k3v + k4v);
        Vector3 dr = h6 * (k1r + 2 * k2r + 2 * k3r + k4r);
        return (dv, dr);
    }
}
