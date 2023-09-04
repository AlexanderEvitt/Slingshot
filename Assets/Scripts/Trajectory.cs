using System;
using System.Collections;
using System.Collections.Generic;
using System.Xml.Linq;
using UnityEngine;
using UnityEngine.UIElements;
using static UnityEngine.GraphicsBuffer;

public class Trajectory : MonoBehaviour
{

    private LineRenderer lr;
    private VisualElement rootVisualElement;
    string[] objects;
    int bodyIndex = 0;
    int counter = 0;
    // Start is called before the first frame update
    void Start()
    {
        objects = new string[] { "Earth", "Moon" , "Sun"};
        rootVisualElement = GameObject.Find("UIDocument").GetComponent<UIDocument>().rootVisualElement;
    }

    // Update is called once per frame
    void Update()
    {
        Vector3[] positions = GameObject.Find("Spacecraft").GetComponent<Propagator>().gamePositions;
        float[] times = GameObject.Find("Spacecraft").GetComponent<Propagator>().times;
        float dist = GameObject.Find("InputController").GetComponent<CameraMovement>().distanceToTarget;
        IntegerField iterationInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ControlsContainer").Q<VisualElement>("IterationLengthContainer").Q<IntegerField>("IterationLength");
        int iteration_length = iterationInput.value;

        if (Input.GetKeyDown("r"))
        {
            bodyIndex = (bodyIndex + 1) % 3;
        }

        if (counter > 20)
        {
            lr = GetComponent<LineRenderer>();
            lr.positionCount = iteration_length;
            lr.startWidth = dist/250;
            lr.endWidth = dist/250;

            for (int i = 0; i < iteration_length; i++)
            {
                lr.SetPosition(i, positions[i]);
            }
            counter = 0;
        }

        counter = counter + 1;
        Vector3 target = GameObject.Find(objects[bodyIndex]).transform.position;
        transform.position = target;

        
    }
}
