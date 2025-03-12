extends Label

var snippets
var i = 0
var done = false
var max_lines = 35

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	snippets = text.split('\n')
	text = ""
	visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !done:
		var t = 200*randf()
		if i < 5:
			t = 0
		await get_tree().create_timer(t).timeout
	
	if !done:
		text = text + snippets[i] + "\n"
		i = i + 1
		if i > max_lines:
			lines_skipped += 1
		if i > snippets.size() - 1:
			done = true
