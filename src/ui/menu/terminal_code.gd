extends Label

# Max seconds in between text fragments
@export var n := 100.0

var snippets
var i = 0
var done = false
# Controls how many lines are visible on screen
var max_lines = 50

func _ready() -> void:
	# Split text by line
	snippets = text.split('\n')
	text = ""
	visible = true


func _process(_delta: float) -> void:
	# Wait a random amount of time up to n seconds
	if !done:
		var t = n*randf()
		# First five lines are instant
		if i < 5:
			t = 0
		await get_tree().create_timer(t).timeout
	
	# Add each snippet to the text
	if !done:
		text = text + snippets[i] + "\n"
		i = i + 1
		if i > max_lines:
			lines_skipped += 1
		if i > snippets.size() - 1:
			done = true
