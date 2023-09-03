using OpenCover.Framework.Model;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.UIElements;

public class Propagator : MonoBehaviour
{
    public Rigidbody Spacecraft;
    public Rigidbody Moon;
    public Vector3d[] positions;
    public Vector3d[] velocities;
    public Vector3d[] accelerations;
    public float[] times;
    int t = 0;
    int skip = 1;
    private Button refreshButton;
    private VisualElement rootVisualElement;
    public int iteration_length = Universe.iteration_length;
    public float currentTime = 0;
    public Vector3 offset = Vector3.zero;
    Vector3d currentPosition = new Vector3d(149604900d,0d,0d);
    public Vector3d currentVelocity = new Vector3d(0d, 0d, 38.3307d);
    

    void Start()
    {
        rootVisualElement = GameObject.Find("UIDocument").GetComponent<UIDocument>().rootVisualElement;
        Refresh();

        refreshButton = rootVisualElement.Q<VisualElement>("SideBar").Q<Button>("RefreshButton");
        refreshButton.clicked += () => Refresh();

        Spacecraft.position = Vector3.zero;
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
            offset = positions[t % iteration_length].backToVec;
            currentVelocity = velocities[t % iteration_length];
            currentTime = times[t % iteration_length];
            Spacecraft.rotation = Quaternion.LookRotation(velocities[t % iteration_length].backToVec.normalized) * Quaternion.Euler(90,0,0);

            currentPosition = positions[t % iteration_length];
        }

        //while (trailer <= t)
        //{
        //    int tr = (trailer) % iteration_length;
        //
        //    (Vector3 dv, Vector3 dr, float dt) = StepRK4(trailer);
        //    velocities[tr] = dv;
        //    positions[tr] = dr;
        //    times[tr] = dt;
        //    if (positions[tr].magnitude > 1e10)
        //    {
        //        int trm = (tr - 1) % iteration_length;
        //        if (trm < 0)
        //        {
        //            trm = iteration_length - 1;
        //        }
        //        positions[tr] = positions[trm];
         //       velocities[tr] = velocities[trm];
        //        times[tr] = times[trm];
        //    }
        //
        //    lr.positionCount = lr.positionCount + 1;
        //    lr.SetPosition(lr.positionCount - 1, positions[tr]);
        //
        //    trailer = trailer + 1;
        //}

        if (t > iteration_length/2)
        {
            Refresh();
        }

        t = t + skip;

    }

    Vector3d acceleration(Vector3d position, int index)
    {
        var celestials = FindObjectsOfType<Celestial>();
        Vector3d accel = Vector3d.zero;
        
        foreach (var c in celestials)
        {
            Vector3d r_to = position - c.place_wrtGlobal(times[index]);
            double sqrDist = r_to.sqrMagnitude;
            accel = accel + r_to.normalized * (Universe.G * c.mass / sqrDist);
        }
        return accel;
        
    }

    (Vector3d dv, Vector3d dr, Vector3d da, float dt) StepRK4(int i)
    {
        int im = (i - 1) % iteration_length;
        if (im < 0)
        {
            im = iteration_length - 1;
        }

        
        float dt = 0.1f / Mathf.Sqrt(acceleration(positions[im], im).backToVec.magnitude);
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

        Vector3d dv = velocities[im] + h6 * (k1v + 2 * k2v + 2 * k3v + k4v) + maneuverDeltaV(i, dt, velocities[im], acceleration(positions[im], im));
        Vector3d dr = positions[im] + h6 * (k1r + 2 * k2r + 2 * k3r + k4r);
        dt = times[im] + dt;

        Vector3d da = h6 * (k1v + 2 * k2v + 2 * k3v + k4v) + maneuverDeltaV(i, dt, velocities[im], acceleration(positions[im], im));


        return (dv, dr, da, dt);
    }

    void Refresh()
    {
        IntegerField iterationInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ControlsContainer").Q<VisualElement>("IterationLengthContainer").Q<IntegerField>("IterationLength");
        iteration_length = iterationInput.value;
        t = 1;

        positions = new Vector3d[iteration_length];
        velocities = new Vector3d[iteration_length];
        accelerations = new Vector3d[iteration_length];
        times = new float[iteration_length];

        positions[0] = currentPosition;
        velocities[0] = currentVelocity;
        times[0] = currentTime;
        


        for (int i = 1; i < iteration_length; i++)
        {

            (Vector3d dv, Vector3d dr, Vector3d da, float dt) = StepRK4(i);
            positions[i] = dr;
            velocities[i] = dv;
            times[i] = dt;
            accelerations[i] = da;
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
                accelerations[i] = accelerations[im];
            }

            
        }

        
    }

    Vector3d maneuverDeltaV(int index,float dt,Vector3d velocity,Vector3d acceleration)
    {
        int im = (index - 1) % iteration_length;
        if (im < 0)
        {
            im = iteration_length - 1;
        }
        Vector4[] maneuvers = GameObject.Find("UIDocument").GetComponent<Maneuver>().maneuvers;
        Vector3d ahat = acceleration.normalized;
        Vector3d vhat = velocity.normalized;
        Vector3d nhat = Vector3d.Cross(vhat,ahat);
        Vector3d rhat = Vector3d.Cross(vhat,nhat);
        Vector3d deltaV = new Vector3d();
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
