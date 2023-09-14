using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Celestial : MonoBehaviour
{
    Transform Planet;
    LineRenderer lr;
    public float SMA = 384400;
    public float start_angle = 0.0f;
    public float period = 2358720.0f;
    public float mass = 0.012345f;
    public float e = 0.0549f;
    public float inclination = 5.1f;
    public string moonOf = "Sun";
    Propagator Propagator;
    CameraMovement Camera;


    // Start is called before the first frame update
    void Start()
    {
        Propagator = GameObject.Find("Spacecraft").GetComponent<Propagator>();
        Camera = GameObject.Find("InputController").GetComponent<CameraMovement>();

        Planet = gameObject.transform;
        inclination = inclination * (Mathf.PI / 180f);

        lr = GetComponent<LineRenderer>();
        lr.positionCount = 390;

        for (int i = 5; i < 395; i++)
        {
            float mean_anomaly = (2 * Mathf.PI * i / 399) + Mathf.PI;
            Vector3 spot = new Vector3(SMA * Mathf.Cos(mean_anomaly) + SMA, 0f, SMA * Mathf.Sin(mean_anomaly));
            lr.SetPosition(i - 5, spot/(Universe.scaleDown*Planet.localScale.x));
        }
    }

    // Update is called once per frame
    void Update()
    {
        float dist = Camera.distanceToTarget;
        float linesize = (dist) / 250;
        lr.widthMultiplier = linesize;

        float time = Propagator.currentTime;
        Planet.position = place_wrtCraft(time) / Universe.scaleDown;
        if (SMA > 0)
        {
            Planet.rotation = Quaternion.LookRotation(place_wrtGlobal(time).backToVec.normalized) * Quaternion.Euler(0, 90, 0);
        }
    }

    public Vector3 place_wrtCraft(float t)
    {
        // Calculates mean anomaly, approximates true anomaly for small eccentricities, rotates around x-axis by the inclination angle
        double mean_anomaly = (t / period) * 2 * Mathd.PI + start_angle;
        double true_anomaly = mean_anomaly + 2 * e * Mathd.Sin(mean_anomaly) + 1.25f * (e * e) * Mathd.Sin(2 * mean_anomaly);
        double r = SMA * (1d - e * e) / (1d + e * Mathd.Cos(true_anomaly));

        Vector3d pos = new Vector3d(r * Mathd.Cos(mean_anomaly), 0, r * Mathd.Sin(mean_anomaly));
        Vector3d transform_pos = new Vector3d(pos.x, Mathd.Cos(inclination) * pos.y - Mathd.Sin(inclination) * pos.z, Mathd.Sin(inclination) * pos.y + Mathd.Cos(inclination) * pos.z);
        if (moonOf != "None")
        {
            transform_pos = transform_pos + GameObject.Find(moonOf).GetComponent<Celestial>().place_wrtGlobal(t);
        }
        Vector3 position = transform_pos.backToVec - Propagator.offset;
        return position;
    }
    public Vector3d place_wrtGlobal(float t)
    {
        // Calculates mean anomaly, approximates true anomaly for small eccentricities, rotates around x-axis by the inclination angle
        double mean_anomaly = (t / period) * 2 * Mathd.PI + start_angle;
        double true_anomaly = mean_anomaly + 2 * e * Mathd.Sin(mean_anomaly) + 1.25f * (e * e) * Mathd.Sin(2 * mean_anomaly);
        double r = SMA * (1d - e * e) / (1d + e * Mathd.Cos(true_anomaly));

        Vector3d pos = new Vector3d(r * Mathd.Cos(mean_anomaly), 0, r * Mathd.Sin(mean_anomaly));
        Vector3d transform_pos = new Vector3d(pos.x, Mathd.Cos(inclination)*pos.y - Mathd.Sin(inclination)*pos.z, Mathd.Sin(inclination)*pos.y + Mathd.Cos(inclination)*pos.z);
        if (moonOf != "None")
        {
            transform_pos = transform_pos + GameObject.Find(moonOf).GetComponent<Celestial>().place_wrtGlobal(t);
        }
        return transform_pos;
    }

    public Vector3d vel_wrtGlobal(float t)
    {
        Vector3d vel = (place_wrtGlobal(t + 1) - place_wrtGlobal(t - 1)) / 2;
        return vel;
    }
}
