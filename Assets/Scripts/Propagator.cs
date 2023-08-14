using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class Propagator : MonoBehaviour
{
    public Rigidbody Spacecraft;
    public Rigidbody Moon;
    private LineRenderer lr;
    float M = 1f;
    float m = 0.012345f;
    public Vector3[] positions;
    public Vector3[] velocities;
    public float[] times;
    int t = 0;
    int trailer;
    int skip = 1;
    public Vector3 velocity;
    private Button refreshButton;
    private VisualElement rootVisualElement;
    public int iteration_length = Universe.iteration_length;
    public float currentTime = 0;

    void Start()
    {
        rootVisualElement = GameObject.Find("UIDocument").GetComponent<UIDocument>().rootVisualElement;
        Refresh();

        refreshButton = rootVisualElement.Q<VisualElement>("SideBar").Q<Button>("RefreshButton");
        refreshButton.clicked += () => Refresh();
    }

    void Update()
    {
        if (Input.GetKeyDown("'"))
        {
            skip = skip*2;
            if (skip == 0)
            {
                skip = 1;
            }
        }
        if (Input.GetKeyDown(";"))
        {
            skip = skip/2;
            if (skip < 1)
            {
                skip = 0;
            }
        }
        
        if (skip > 0)
        {
            Spacecraft.position = positions[t % iteration_length];
            velocity = velocities[t % iteration_length];
            currentTime = times[t % iteration_length];
            Spacecraft.rotation = Quaternion.LookRotation(velocities[t % iteration_length].normalized) * Quaternion.Euler(90,0,0);
        }

        while (trailer <= t)
        {
            int tr = (trailer) % iteration_length;
        
            (Vector3 dv, Vector3 dr, float dt) = StepRK4(trailer);
            velocities[tr] = dv;
            positions[tr] = dr;
            times[tr] = dt;
            if (positions[tr].magnitude > 1e10)
            {
                int trm = (tr - 1) % iteration_length;
                if (trm < 0)
                {
                    trm = iteration_length - 1;
                }
                positions[tr] = positions[trm];
                velocities[tr] = velocities[trm];
                times[tr] = times[trm];
            }

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

    (Vector3 dv, Vector3 dr, float dt) StepRK4(int i)
    {
        int im = (i - 1) % iteration_length;
        if (im < 0)
        {
            im = iteration_length - 1;
        }

        Vector3 moon_position = GameObject.Find("Moon").GetComponent<MoonOrbit>().moon_place(times[im]);
        float dt = 2.0f / Mathf.Sqrt(acceleration(positions[im], moon_position).magnitude);
        float h2 = (float)(dt) / 2;
        float h6 = (float)(dt) / 6;

        Vector3 k1v = acceleration(positions[im], moon_position);
        Vector3 k1r = velocities[im];

        Vector3 k2v = acceleration(positions[im] + k1r * h2, moon_position);
        Vector3 k2r = velocities[im] + k1v * h2;

        Vector3 k3v = acceleration(positions[im] + k2r * h2, moon_position);
        Vector3 k3r = velocities[im] + k2v * h2;

        Vector3 k4v = acceleration(positions[im] + k3r * dt, moon_position);
        Vector3 k4r = velocities[im] + k3v * dt;
        
        Vector3 dv = velocities[im] + h6 * (k1v + 2 * k2v + 2 * k3v + k4v) + maneuverDeltaV(i, dt, velocities[im], acceleration(positions[im], moon_position));
        Vector3 dr = positions[im] + h6 * (k1r + 2 * k2r + 2 * k3r + k4r);
        dt = times[im] + dt;

        return (dv, dr, dt);
    }

    void Refresh()
    {
        IntegerField iterationInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ControlsContainer").Q<VisualElement>("IterationLengthContainer").Q<IntegerField>("IterationLength");
        iteration_length = iterationInput.value;
        t = 1;
        trailer = 0;

        positions = new Vector3[iteration_length];
        velocities = new Vector3[iteration_length];
        times = new float[iteration_length];

        positions[0] = Spacecraft.position;
        velocities[0] = velocity;
        times[0] = currentTime;
        lr = GetComponent<LineRenderer>();
        lr.positionCount = iteration_length;
        lr.SetPosition(0, positions[0]);


        for (int i = 1; i < iteration_length; i++)
        {

            (Vector3 dv, Vector3 dr, float dt) = StepRK4(i);
            positions[i] = dr;
            velocities[i] = dv;
            times[i] = dt;
            if (positions[i].magnitude > 1e10)
            {
                int im = (i - 1) % iteration_length;
                if (i < 0)
                {
                    im = iteration_length - 1;
                }
                positions[i] = positions[im];
                velocities[i] = velocities[im];
                times[i] = times[im];
            }

            lr.SetPosition(i, positions[i]);
        }

        
    }

    Vector3 maneuverDeltaV(int index,float dt,Vector3 velocity,Vector3 acceleration)
    {
        int im = (index - 1) % iteration_length;
        if (im < 0)
        {
            im = iteration_length - 1;
        }
        Vector4[] maneuvers = GameObject.Find("UIDocument").GetComponent<Maneuver>().maneuvers;
        Vector3 ahat = acceleration.normalized;
        Vector3 vhat = velocity.normalized;
        Vector3 nhat = Vector3.Cross(vhat,ahat);
        Vector3 rhat = Vector3.Cross(vhat,nhat);
        Vector3 deltaV = new Vector3();
        for (int i = 0; i < maneuvers.Length; i++)
        {
            if ((dt + times[im]) - maneuvers[i].x < 1.1f*dt && (dt + times[im]) - maneuvers[i].x > 0)
            {
                deltaV = maneuvers[i].y * vhat + maneuvers[i].z * nhat + maneuvers[i].w * rhat;
            }
        }
        return deltaV;
    }
}
