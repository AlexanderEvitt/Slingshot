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
    public int t;
    public int time = 0;
    int trailer;
    public int skip = 1;
    public Vector3 velocity;
    private Button refreshButton;
    private VisualElement rootVisualElement;
    public int iteration_length = Universe.iteration_length;
    public int time_step = Universe.time_step;

    // Start is called before the first frame update
    void Start()
    {
        rootVisualElement = GameObject.Find("UIDocument").GetComponent<UIDocument>().rootVisualElement;
        Refresh();

        
        refreshButton = rootVisualElement.Q<VisualElement>("SideBar").Q<Button>("RefreshButton");
        refreshButton.clicked += () => Refresh();
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
            Spacecraft.position = positions[t % iteration_length];
            velocity = velocities[t % iteration_length];
            Spacecraft.rotation = Quaternion.LookRotation(velocities[t % iteration_length].normalized) * Quaternion.Euler(90,0,0);
        }
        
        while (trailer <= t)
        {
            int trm = (trailer - 1) % iteration_length;
            if (trm < 0)
            {
                trm = iteration_length - 1;
            }
            int tr = (trailer) % iteration_length;

            (Vector3 dv, Vector3 dr) = RungeKutta4(trm,trailer);
            velocities[tr] = velocities[trm] + dv + maneuverDeltaV(trailer, velocities[trm], acceleration(positions[trm], GameObject.Find("Moon").GetComponent<MoonOrbit>().moon_place(trailer)));
            positions[tr] = positions[trm] + dr;
            
            lr.positionCount = lr.positionCount + 1;
            lr.SetPosition(lr.positionCount - 1, positions[tr]);

            trailer = trailer + 1;
        }       

        t = t + skip;
        time = time + skip;
    }

    Vector3 acceleration(Vector3 position, Vector3 moon_position)
    {
        Vector3 r_moon = position - moon_position;
        float sqrtDist = (position).sqrMagnitude;
        float sqrtDistMoon = r_moon.sqrMagnitude;
        Vector3 accel = position.normalized * (Universe.G * M / sqrtDist) + r_moon.normalized * (Universe.G * m / sqrtDistMoon);
        return accel;
    }

    (Vector3 dv, Vector3 dr) RungeKutta4(int i,int ia)
    {
        float h2 = (float)(Universe.time_step) / 2;
        float h6 = (float)(Universe.time_step) / 6;
        Vector3 moon_position = GameObject.Find("Moon").GetComponent<MoonOrbit>().moon_place(ia);

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

    void Refresh()
    {
        IntegerField iterationInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ControlsContainer").Q<VisualElement>("IterationLengthContainer").Q<IntegerField>("IterationLength");
        iteration_length = iterationInput.value;
        t = 1;
        trailer = 0;

        positions = new Vector3[iteration_length];
        velocities = new Vector3[iteration_length];

        positions[0] = Spacecraft.position;
        velocities[0] = velocity;
        lr = GetComponent<LineRenderer>();
        lr.positionCount = iteration_length;
        lr.SetPosition(0, positions[0]);


        for (int i = 1; i < iteration_length; i++)
        {

            (Vector3 dv, Vector3 dr) = RungeKutta4(i - 1,i - 1);
            Vector3 mdv = maneuverDeltaV(time + i - 1, velocities[i - 1], acceleration(positions[i - 1], GameObject.Find("Moon").GetComponent<MoonOrbit>().moon_place(time + i - 1)));
            velocities[i] = velocities[i - 1] + dv + mdv;
            if (mdv.magnitude > 0)
            {
                Debug.Log(mdv);
            }
            
            positions[i] = positions[i - 1] + dr;

            lr.SetPosition(i, positions[i]);
        }
    }

    Vector3 maneuverDeltaV(int time,Vector3 vellie,Vector3 acceleration)
    {
        Vector4[] maneuvers = GameObject.Find("UIDocument").GetComponent<Maneuver>().maneuvers;
        Vector3 ahat = acceleration.normalized;
        Vector3 vhat = vellie.normalized;
        Vector3 nhat = Vector3.Cross(vhat,ahat);
        Vector3 rhat = Vector3.Cross(vhat,nhat);
        Vector3 deltaV = new Vector3();
        for (int i = 0; i < maneuvers.Length; i++)
        {
            if (maneuvers[i].x == time)
            {
                deltaV = maneuvers[i].y * vhat + maneuvers[i].z * nhat + maneuvers[i].w * rhat;
            }
        }
        return deltaV;
    }
}
