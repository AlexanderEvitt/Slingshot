using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class Display : MonoBehaviour
{
    private Label velocityCounter;
    private Label timeCounter;
    private Label altitudeCounter;
    private Label inclinationCounter;
    private Label eccentricityCounter;
    private Vector3 vel;
    private Vector3 r;
    // Start is called before the first frame update
    void Start()
    {
        var rootVisualElement = GetComponent<UIDocument>().rootVisualElement;
        velocityCounter = rootVisualElement.Q<VisualElement>("TopBar").Q<VisualElement>("VelocityContainer").Q<Label>("Velocity");
        timeCounter = rootVisualElement.Q<VisualElement>("TopBar").Q<VisualElement>("TimeContainer").Q<Label>("Time");
        altitudeCounter = rootVisualElement.Q<VisualElement>("TopBar").Q<VisualElement>("AltitudeContainer").Q<Label>("Altitude");
        inclinationCounter = rootVisualElement.Q<VisualElement>("TopBar").Q<VisualElement>("InclinationContainer").Q<Label>("Inclination");
        eccentricityCounter = rootVisualElement.Q<VisualElement>("TopBar").Q<VisualElement>("EccentricityContainer").Q<Label>("Eccentricity");
    }

    // Update is called once per frame
    void Update()
    {
        vel = (Vector3)GameObject.Find("Spacecraft").GetComponent<Propagator>().currentVelocity;
        r = GameObject.Find("Earth").transform.position - GameObject.Find("Spacecraft").transform.position;  // craft to earth

        // update velocity
        velocityCounter.text = $"{(int)(1000 * vel.magnitude)} m/s";

        ChangeTimeCounter();

        ChangeAltitude(r);

        ChangeInclination(vel, r);

        ChangeEccentricity(vel, r);
    }

    void ChangeTimeCounter()
    {
        int t = (int)GameObject.Find("Spacecraft").GetComponent<Propagator>().currentTime;
        string min = "" + (t / 60) % 60;
        string hr = "" + (t / 3600) % 24;
        string day = "" + t / 86400;
        if (min.Length < 2)
        {
            min = "0" + min;
        }

        if (hr.Length < 2)
        {
            hr = "0" + hr;
        }

        if (day.Length < 2)
        {
            day = "0" + day;
        }
        timeCounter.text = $"T+{day}:{hr}:{min}";
    }

    void ChangeAltitude(Vector3 r)
    {
        int altitude = (int)(r.magnitude) - 6371;  // km
        altitudeCounter.text = $"{altitude} km";
    }

    void ChangeInclination(Vector3 r, Vector3 vel)
    {
        // instantaneous inclination
        Vector3 movingNorm = Vector3.Cross(vel, r);
        int inclination = (int)Vector3.Angle(movingNorm, Vector3.down);
        inclinationCounter.text = $"{inclination} degrees";

    }

    void ChangeEccentricity(Vector3 r, Vector3 vel)
    {
        Vector3 h = Vector3.Cross(r, vel);
        float mu = Universe.G * -1;  // km^3 / s^2
        Vector3 e = (Vector3.Cross(vel, h) / mu) - (r / r.magnitude);
        eccentricityCounter.text = $"{e.magnitude}";
    }
}