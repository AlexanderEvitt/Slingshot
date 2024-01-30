using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Universe
{
    public const float G = -398602.5f;
    public const int iteration_length = 10000;
    public const int scaleDown = 2000;
    public static readonly string[] objects = new string[] { "Sun", "Mercury", "Venus", "Earth", "Moon", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune" };
    public static double[] fence = new double[] {1200000d, 240000d, 1600000d, 50000000d, 1d, 1100000d, 70000000d, 120000000d, 70000000d, 60000000d};
}