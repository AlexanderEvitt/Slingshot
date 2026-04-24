@tool
extends Node3D

func _ready() -> void:
	var sampler := HeightmapSampler.new()
	sampler.load_from_path("res://scenes/simulation/bodies/chunked_planet/moon_height.png")

	# Sample a few known directions and print results
	var tests := {
		"north pole":  Vector3(0, 1, 0),
		"south pole":  Vector3(0, -1, 0),
		"prime merid": Vector3(0, 0, 1),
		"90 east":     Vector3(1, 0, 0),
	}
	for label in tests:
		var h := sampler.sample(tests[label])
		print("%s -> %.4f" % [label, h])
