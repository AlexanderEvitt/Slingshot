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
    int bodyIndex = 3;
    int counter = 0;
    Propagator Propagator;
    CameraMovement Camera;
    IntegerField iterationInput;

    // Start is called before the first frame update
    void Start()
    {
        rootVisualElement = GameObject.Find("UIDocument").GetComponent<UIDocument>().rootVisualElement;

        Propagator = GameObject.Find("Spacecraft").GetComponent<Propagator>();
        Camera = GameObject.Find("InputController").GetComponent<CameraMovement>();
        iterationInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ControlsContainer").Q<VisualElement>("IterationLengthContainer").Q<IntegerField>("IterationLength");

    }

    // Update is called once per frame
    void Update()
    {
        Vector3[] positions = Propagator.gamePositions;
        float[] times = Propagator.times;
        float dist = Camera.distanceToTarget;
        int iteration_length = iterationInput.value;

        // This bit moves the reference frame to the next planet if r is pressed, or to the previous if shift+R is pressed
        if (Input.GetKeyDown("r"))
        {
            if (Input.GetKey(KeyCode.LeftControl))
            {
                bodyIndex = (bodyIndex - 1);
                if (bodyIndex <= 0)
                {
                    bodyIndex = 9;
                }
            }
            else
            {
                bodyIndex = (bodyIndex + 1) % 10;
            }
            Debug.Log(bodyIndex);
        }

        

        if (counter > 0)
        {
            lr = GetComponent<LineRenderer>();
            lr.positionCount = positions.Length;
            lr.startWidth = dist/250;
            lr.endWidth = dist/250;

            for (int i = 0; i < positions.Length; i++)
            {
                lr.SetPosition(i, positions[i]);
            }
            counter = 0;
        }

        counter = counter + 1;
        Vector3 target = GameObject.Find(Universe.objects[bodyIndex]).transform.position;
        transform.position = target;

        
    }
}
