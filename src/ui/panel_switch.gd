extends Control

var panels
var buttons
var h = 0

var old_panel
var new_panel

var transition_time = 0.25

# Assume all buttons are under buttons_parent
# w/ 1 layer in between
@export var buttons_parent : Node
@export var panels_parent : Node

# Get refs to all the HUDs and buttons
func _ready():
	panels = panels_parent.get_children()
	buttons = buttons_parent.get_children()
	
	# Bind each button to a set_huds function
	var k = 0
	for b in buttons:
		# Swap out for actual button instead of parent of button
		buttons[k] = b.get_child(0)
		# Connect signal to change HUD function
		b.get_child(0).pressed.connect(set_panel.bind(k))
		k += 1

	# Initialize with first panel
	set_panel(0)

func set_panel(i):
	h = i # used for keeping track of which HUD is active
	
	# Set all the buttons to be un-toggled except the one just pressed
	# Necessary because the arrow keys won't caues the button to be pressed
	for b in buttons:
		if buttons.find(b,0) == i:
			b.set_pressed_no_signal(true)
		else:
			b.set_pressed_no_signal(false)
	
	# Set the correct HUD to be visible
	for p in panels:
		if panels.find(p,0) == i:
			new_panel = p
		else:
			p.visible = false
		
	# Swap visibility
	new_panel.visible = true
	old_panel = new_panel
