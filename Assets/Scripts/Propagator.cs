using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Xml.Linq;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UIElements;

public class Propagator : MonoBehaviour
{
    Transform Spacecraft;
    public Vector3d[] positions;
    public Vector3d[] velocities;
    public Vector3[] gamePositions;
    public Vector3[] gameVelocities;
    public float[] times;
    int t = 1;
    public int bodyIndex = 3;
    int rateTime = 1;
    private Button refreshButton;
    private VisualElement rootVisualElement;
    public int iteration_length = Universe.iteration_length;
    public float currentTime = 0;
    public Vector3 offset = Vector3.zero;
    Vector3d lastPosition = new Vector3d(147105000d,0d,0d);
    public Vector3d lastVelocity = new Vector3d(0d, 0d, 39.20d);
    public float lastTime = 0;
    public Vector3 currentGameVelocity = new Vector3(0f, 0f, 0f);
    public Vector3 currentGamePosition = new Vector3(0f, 0f, 0f);
    public Celestial[] celestials;
    CameraMovement Camera;
    public Vector4[] maneuvers;
    public string[] references;

    void Start()
    {
        // Gathers all the relevant objects that affect the spacecraft
        celestials = FindObjectsOfType<Celestial>();
        Camera = GameObject.Find("InputController").GetComponent<CameraMovement>();
        Spacecraft = gameObject.transform;
        rootVisualElement = GameObject.Find("UIDocument").GetComponent<UIDocument>().rootVisualElement;

        // Refresh the trajectory whenver the refresh button is pushed
        StartCoroutine(Refresh());
        refreshButton = rootVisualElement.Q<VisualElement>("SideBar").Q<Button>("RefreshButton");
        refreshButton.clicked += () => StartCoroutine(Refresh());

        // Spacecraft is fixed to the origin of the system, planets move around it
        Spacecraft.position = Vector3.zero;
    }

    void Update()
    {
        // Accelerate time by 2x whenever ' is pressed, decelerate by 1/2x whenever ; is pressed, pause if small
        if (Input.GetKeyDown("'"))
        {
            rateTime = rateTime*2;
            if (rateTime == 0)
            {
                rateTime = 1;
            }
        }
        if (Input.GetKeyDown(";"))
        {
            rateTime = rateTime /2;
            if (rateTime < 1)
            {
                rateTime = 0;
            }
        }

        // Advance the current index by this quantity
        currentTime = currentTime + 0.02f * rateTime;
        float stepTime = times[t + 1] - times[t];
        if (currentTime > times[t] + stepTime)
        {
            t = t + (int)((currentTime - times[t]) / stepTime);
        }

        if (rateTime > 0)
        {
            // Offset tells the other planets how to move
            offset = interpolate(positions[t].backToVec, positions[t + 1].backToVec, times[t], currentTime, times[t + 1]);
            
            // These tell the displays how to display altitude and velocity
            currentGameVelocity = interpolate(gameVelocities[t], gameVelocities[t + 1], times[t], currentTime, times[t + 1]);
            currentGamePosition = interpolate(gamePositions[t], gamePositions[t + 1], times[t], currentTime, times[t + 1]);
            
            // These instantiate the next refresh cycle
            lastPosition = positions[t];
            lastVelocity = velocities[t];
            lastTime = times[t];
        }
        

        // Point the spacecraft in the prograde direction and scale it with the camera
        Spacecraft.rotation = Quaternion.LookRotation(currentGameVelocity.normalized) * Quaternion.Euler(0, 90, 0);
        float dist = Camera.distanceToTarget;
        Spacecraft.localScale = new Vector3(dist/65, dist/100, dist/100);


        // Refresh the trajectory if the spacecraft is more than 1/5th along the route
        if (t > iteration_length/5)
        {
            StartCoroutine(Refresh());
        }

        // This bit moves the reference frame to the next planet if r is pressed, or to the previous if shift+R is pressed
        if (Input.GetKeyDown("r"))
        {
            if (Input.GetKey(KeyCode.LeftControl))
            {
                bodyIndex = (bodyIndex - 1);
                if (bodyIndex < 0)
                {
                    bodyIndex = 9;
                }
            }
            else
            {
                bodyIndex = (bodyIndex + 1) % 10;
            }
        }
    }

    Vector3d acceleration(Vector3d position, int index)
    {
        Vector3d accel = Vector3d.zero;
        
        foreach (var c in celestials)
        {
            Vector3d r_to = position - c.place_wrtGlobal(times[index]);
            double sqrDist = r_to.sqrMagnitude;
            accel = accel + r_to.normalized * (Universe.G * c.mass / sqrDist);
        }
        return accel;
        
    }

    (Vector3d vn, Vector3d rn, float tn) StepRK4(int i)
    {
        int im = (i - 1) % iteration_length;
        if (im < 0)
        {
            im = iteration_length - 1;
        }

        // Time step scales with acceleration, providing higher fidelity close to bodies. Adaptive time stepping is currently unstable. Future work will fix this.
        float dt = 0.01f / acceleration(positions[im], im).backToVec.magnitude;
        float h2 = (float)(dt) / 2;
        float h6 = (float)(dt) / 6;

        Vector3d k1v = acceleration(positions[im], im);
        Vector3d k1r = velocities[im];

        Vector3d k2v = acceleration(positions[im] + k1r * h2, im);
        Vector3d k2r = velocities[im] + k1v * h2;

        Vector3d k3v = acceleration(positions[im] + k2r * h2, im);
        Vector3d k3r = velocities[im] + k2v * h2;

        Vector3d k4v = acceleration(positions[im] + k3r * dt, im);
        Vector3d k4r = velocities[im] + k3v * dt;

        Vector3d vn = velocities[im] + h6 * (k1v + 2 * k2v + 2 * k3v + k4v) + maneuverDeltaV(i, dt, positions[im], velocities[im], maneuvers, references);
        Vector3d rn = positions[im] + h6 * (k1r + 2 * k2r + 2 * k3r + k4r);
        float tn = times[im] + dt;

        return (vn, rn, tn);
    }

    (Vector3d vn, Vector3d rn, float tn) StepForestRuth(int i)
    {
        /*
        Forest-Ruth numerical integration algorithm as described in https://etda.libraries.psu.edu/files/final_submissions/11742
        Except there's some modifications, plus a pseudo-adaptive time step algorithm
        */

        // Calculate the index of the last timestep
        int im = (i - 1) % iteration_length;
        if (im < 0)
        {
            im = iteration_length - 1;
        }

        // Use a gigantic timestep OR a much smaller one if the spacecraft is closer to any body than that body's "fence" (defined roughly as the distance to the L1 point)
        float dt = 6000f;
        for (int j = 0; j < celestials.Length; j++)
        {
            double distance = (positions[im] - celestials[j].place_wrtGlobal(times[im])).magnitude;
            if (distance < Universe.fence[j])
            {
                dt = 60f;
            }
        }

        Vector3d r1 = positions[im] + velocities[im] * (dt / 2);
        Vector3d v1 = velocities[im] + acceleration(r1, im) * dt;

        Vector3d r2 = r1;
        Vector3d v2 = v1 - acceleration(r2,im) * dt;

        Vector3d rn = r2 + v2 * (dt / 2);
        Vector3d vn = v2 + acceleration(rn, im) * dt + maneuverDeltaV(i, dt, positions[im], velocities[im], maneuvers, references);
        float tn = times[im] + dt;

        return (vn, rn, tn);
    }

    IEnumerator Refresh()
    {
        // Get how many iterations to do
        IntegerField iterationInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ControlsContainer").Q<VisualElement>("IterationLengthContainer").Q<IntegerField>("IterationLength");
        iteration_length = iterationInput.value;
        
        // Initialize, game prefix indicates that the variable refers to a reference frame centered on the reference celestial body (to plot trajectory in other frames)
        t = 1;
        positions = new Vector3d[iteration_length];
        velocities = new Vector3d[iteration_length];
        times = new float[iteration_length];
        gamePositions = new Vector3[positions.Length];
        gameVelocities = new Vector3[positions.Length];

        positions[0] = lastPosition;
        velocities[0] = lastVelocity;
        times[0] = lastTime;

        // Pull the maneuver velocities and what frame they're in
        maneuvers = GameObject.Find("UIDocument").GetComponent<Maneuver>().maneuvers;
        references = GameObject.Find("UIDocument").GetComponent<Maneuver>().references;
        Celestial refCelest = GameObject.Find(Universe.objects[bodyIndex]).GetComponent<Celestial>();

        // Iterate through the time steps
        for (int i = 1; i < iteration_length; i++)
        {
            (velocities[i], positions[i], times[i]) = StepForestRuth(i);
            
            gamePositions[i] = ((positions[i] - refCelest.place_wrtGlobal(times[i])) / Universe.scaleDown).backToVec;
            gameVelocities[i] = velocities[i].backToVec - refCelest.vel_wrtGlobal(times[i]).backToVec;

            // Handle shooting off into infinity
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
                gamePositions[i] = gamePositions[im];
                gameVelocities[i] = gameVelocities[im];
            }

            if (i % 500 == 0)
            {
                yield return null;
            }
            
        }

        // Check if this is necessary
        (gamePositions, gameVelocities) = toGamePos(positions, Universe.objects[bodyIndex]);
        
    }

    Vector3d maneuverDeltaV(int index,float dt,Vector3d position,Vector3d velocity, Vector4[] maneuvers, string[] references)
    {
        int im = (index - 1) % iteration_length;
        if (im < 0)
        {
            im = iteration_length - 1;
        }

        Vector3d deltaV = new Vector3d();
        for (int i = 0; i < maneuvers.Length; i++)
        {
            if ((dt + times[im]) - maneuvers[i].x < 1.1f*dt && (dt + times[im]) - maneuvers[i].x > 0)
            {
                Vector3d chat = (position - GameObject.Find(references[i]).GetComponent<Celestial>().place_wrtGlobal(times[i])).normalized;
                Vector3d vhat = (velocity - GameObject.Find(references[i]).GetComponent<Celestial>().vel_wrtGlobal(times[i])).normalized;
                Vector3d nhat = Vector3d.Cross(vhat, chat).normalized;
                Vector3d rhat = Vector3d.Cross(vhat, nhat).normalized;
                deltaV = maneuvers[i].y * vhat + maneuvers[i].z * nhat + maneuvers[i].w * rhat;
                maneuvers[i].y = 0;
                maneuvers[i].z = 0;
                maneuvers[i].w = 0;
            }
        }
        return deltaV;
    }

    (Vector3[], Vector3[]) toGamePos(Vector3d[] positions, string body)
    {
        // Puts coordinates into scaled-down and relative to a given body
        gamePositions = new Vector3[positions.Length];
        gameVelocities = new Vector3[positions.Length];
        for (int i = 0; i < positions.Length; i++)
        {
            gamePositions[i] = ((positions[i] - GameObject.Find(body).GetComponent<Celestial>().place_wrtGlobal(times[i])) / Universe.scaleDown).backToVec;
        }
        for (int i = 0; i < positions.Length - 1; i++)
        { 
            gameVelocities[i] = Universe.scaleDown*(gamePositions[i+1] - gamePositions[i]) / (times[i+1] - times[i]);
        }
        gameVelocities[positions.Length - 1] = gameVelocities[positions.Length - 2];
        return (gamePositions, gameVelocities);
    }

    Vector3 interpolate(Vector3 startVal, Vector3 endVal, float startTime, float currentTime, float endTime) 
    {
        return (startVal + (currentTime-startTime)*((endVal-startVal)/(endTime-startTime)));
    }

}
