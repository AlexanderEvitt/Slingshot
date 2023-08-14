using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoonOrbit : MonoBehaviour
{
    public Rigidbody Moon;
    private LineRenderer lr;
    private int moon_height = 384400;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        float time = GameObject.Find("Spacecraft").GetComponent<Propagator>().currentTime;
        Moon.position = moon_place(time);
    }

    public Vector3 moon_place(float t)
    {
        float angle = (t/ 2358720.0f) * 2.0f * Mathf.PI;
        Vector3 pos = new Vector3(moon_height * Mathf.Cos(angle), 0, moon_height * Mathf.Sin(angle));
        return pos;
    }
}
