using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor;

public class Maneuver : MonoBehaviour
{
    public VisualElement rootVisualElement;
    public Button addButton;
    public Vector4[] maneuvers;
    public char maneuverCount = 'A';
    // Start is called before the first frame update
    void Start()
    {
        rootVisualElement = GetComponent<UIDocument>().rootVisualElement;
        addButton = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ManeuverContainer").Q<Button>("AddManeuver");
        addButton.clicked += () => AddManeuver();
    }

    // Update is called once per frame
    void Update()
    {
        int numManeuvers = (int)maneuverCount - 'A';
        maneuvers = new Vector4[numManeuvers];
        char counter = 'A';
        for (int i = 0; i < numManeuvers; i++)
        {
            
            IntegerField placeInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ManeuverContainer").Q<ScrollView>("ManeuverScroll").Q<VisualElement>(counter.ToString()).Q<VisualElement>("PlaceContainer").Q<IntegerField>("Place");
            int place = placeInput.value;
            FloatField progradeInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ManeuverContainer").Q<ScrollView>("ManeuverScroll").Q<VisualElement>(counter.ToString()).Q<VisualElement>("DeltaVContainer").Q<FloatField>("Prograde");
            float prograde = progradeInput.value;
            FloatField normalInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ManeuverContainer").Q<ScrollView>("ManeuverScroll").Q<VisualElement>(counter.ToString()).Q<VisualElement>("DeltaVContainer").Q<FloatField>("Normal");
            float normal = normalInput.value;
            FloatField radialInput = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ManeuverContainer").Q<ScrollView>("ManeuverScroll").Q<VisualElement>(counter.ToString()).Q<VisualElement>("DeltaVContainer").Q<FloatField>("Radial");
            float radial = radialInput.value;

            maneuvers[i] = new Vector4(place, prograde, normal, radial);

            counter++;
        }
    }
    void AddManeuver()
    {
        // Get location to add new maneuver and maneuver
        VisualElement insertLocation = rootVisualElement.Q<VisualElement>("SideBar").Q<VisualElement>("ManeuverContainer").Q<VisualElement>("ManeuverScroll");
        var maneuverBlock = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>("Assets/UI/ManeuverBlock.uxml");
        VisualElement newBlock = maneuverBlock.Instantiate();
        // Change text and name to maneuver name
        Label newBlockText = newBlock.Q<VisualElement>("Maneuver").Q<VisualElement>("PlaceContainer").Q<Label>("PlaceLabel");
        newBlockText.text = $"Burn {maneuverCount} - Time:";
        VisualElement maneuverName = newBlock.Q<VisualElement>("Maneuver");
        maneuverName.name = maneuverCount.ToString();
        // Insert into location and iterate
        insertLocation.Add(newBlock);
        maneuverCount++;

    }
}
