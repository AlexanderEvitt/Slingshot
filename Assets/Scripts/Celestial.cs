using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Celestial : MonoBehaviour
{
    public Rigidbody rb;
    private LineRenderer lr;
    public float SMA = 384400;
    public float start_angle = 0.0f;
    public float period = 2358720.0f;
    public float mass = 0.012345f;
    public string moonOf = "Sun";

    // Start is called before the first frame update
    void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    void Update()
    {
        float time = GameObject.Find("Spacecraft").GetComponent<Propagator>().currentTime;
        rb.position = place_wrtCraft(time) / 100000;
    }

    public Vector3 place_wrtCraft(float t)
    {
        float mean_anomaly = (t/ period) * 2 * Mathf.PI + start_angle;

        Vector3 pos = new Vector3(SMA * Mathf.Cos(mean_anomaly), 0, SMA * Mathf.Sin(mean_anomaly));
        pos = pos - GameObject.Find("Spacecraft").GetComponent<Propagator>().offset;
        if (moonOf != "None")
        {
            pos = pos + GameObject.Find(moonOf).GetComponent<Celestial>().place_wrtGlobal(t);
        }
        return pos;
    }

    public Vector3 place_wrtGlobal(float t)
    {
        float mean_anomaly = (t / period) * 2 * Mathf.PI + start_angle;

        Vector3 pos = new Vector3(SMA * Mathf.Cos(mean_anomaly), 0, SMA * Mathf.Sin(mean_anomaly));
        if (moonOf != "None")
        {
            pos = pos + GameObject.Find(moonOf).GetComponent<Celestial>().place_wrtGlobal(t);
        }
        return pos;
    }
}
