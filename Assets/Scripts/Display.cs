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
    private int vel;
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
        vel = 1;//(int)(1000*(GameObject.Find("Spacecraft").GetComponent<Propagator>().velocity.magnitude));
        velocityCounter.text = $"{vel} m/s";

        int t = Universe.time_step*GameObject.Find("Spacecraft").GetComponent<Propagator>().time;
        string min = "" + (t/60) % 60;
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
}
