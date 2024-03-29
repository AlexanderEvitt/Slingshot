using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    [SerializeField] private Camera cam;
    [SerializeField] private Transform target;
    [SerializeField] public float distanceToTarget = 0.2f;
    int index = 3;
    public string[] objects;
    private Vector3 previousPosition;

    void Start()
    {
        target = GameObject.Find("Spacecraft").transform;
        objects = new string[] { "Sun", "Mercury", "Venus", "Spacecraft", "Earth" , "Moon" , "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"};
    }


    void Update()
    {
        if (Input.GetKeyDown("v"))
        {
            index = (index + 1) % 11;
            target = GameObject.Find(objects[index]).transform;
        }
        distanceToTarget = distanceToTarget - 0.1f*Input.mouseScrollDelta.y*distanceToTarget;
        if (Input.GetKey("x"))
        {
            distanceToTarget = distanceToTarget + 100;
        }
        if (Input.GetKey("z"))
        {
            distanceToTarget = distanceToTarget - 100;
        }
        if (Input.GetMouseButtonDown(1))
        {
            previousPosition = cam.ScreenToViewportPoint(Input.mousePosition);
        }
        else if (Input.GetMouseButton(1))
        {
            Vector3 newPosition = cam.ScreenToViewportPoint(Input.mousePosition);
            Vector3 direction = previousPosition - newPosition;

            float rotationAroundYAxis = -direction.x * 180; // camera moves horizontally
            float rotationAroundXAxis = direction.y * 180; // camera moves vertically

            cam.transform.position = target.position;

            cam.transform.Rotate(new Vector3(1, 0, 0), rotationAroundXAxis);
            cam.transform.Rotate(new Vector3(0, 1, 0), rotationAroundYAxis, Space.World);

            cam.transform.Translate(new Vector3(0, 0, -distanceToTarget));

            previousPosition = newPosition;
        }
        else
        {
            cam.transform.position = target.position;
            cam.transform.Translate(new Vector3(0, 0, -distanceToTarget));
        }
    }
}