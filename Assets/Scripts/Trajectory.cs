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
    int index = 0;
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
        Vector3[] positions = GameObject.Find("Spacecraft").GetComponent<Propagator>().positions;
        float[] times = GameObject.Find("Spacecraft").GetComponent<Propagator>().times;
        IntegerField iterationInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ControlsContainer").Q<VisualElement>("IterationLengthContainer").Q<IntegerField>("IterationLength");
        int iteration_length = iterationInput.value;

        if (Input.GetKeyDown("r"))
        {
            index = (index + 1) % 3;

            lr = GetComponent<LineRenderer>();
            lr.positionCount = iteration_length;

            for (int i = 0; i < iteration_length; i++)
            {
                lr.SetPosition(i, positions[i] - GameObject.Find(objects[index]).GetComponent<Celestial>().place_wrtGlobal(times[i]));
            }
        }

        if (counter > 20)
        {
            lr = GetComponent<LineRenderer>();
            lr.positionCount = iteration_length;

            for (int i = 0; i < iteration_length; i++)
            {
                lr.SetPosition(i, (positions[i] - GameObject.Find(objects[index]).GetComponent<Celestial>().place_wrtGlobal(times[i]))/100000 );
            }
            counter = 0;
        }

        counter = counter + 1;
        Vector3 target = GameObject.Find(objects[index]).transform.position;
        transform.position = target;

        
    }
}
