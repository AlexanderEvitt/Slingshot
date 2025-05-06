extends Control

var panels
var buttons
var h = 0

var old_panel
var new_panel

var transition_time = 0.25

# Control whether to tween
# If so, must have a shifter child that is used to move thing on and off screen
@export var smooth : bool

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

func _input(_event):
	# Check if player is moving around the view with the shift key
	var is_shift = Input.is_action_just_pressed("mod_up") or Input.is_action_just_pressed("mod_down") or Input.is_action_just_pressed("mod_left") or Input.is_action_just_pressed("mod_right")
	# Handle arrow keys switching HUD
	if !is_shift:
		if Input.is_action_just_pressed("arrow_up"):
			h = h - 4
			h = clamp(h,0,7)
			set_panel(h)
		elif Input.is_action_just_pressed("arrow_down"):
			h = h + 4
			h = clamp(h,0,7)
			set_panel(h)
		elif Input.is_action_just_pressed("arrow_left"):
			h = h - 1
			h = clamp(h,0,7)
			set_panel(h)
		elif Input.is_action_just_pressed("arrow_right"):
			h = h + 1
			h = clamp(h,0,7)
			set_panel(h)

func set_panel(i):
	h = i # used for keeping track of which HUD is active
	
	# Set all the buttons to be un-toggled except the one just pressed
	for b in buttons:
		if buttons.find(b,0) == i:
			b.set_pressed_no_signal(true)
		else:
			b.set_pressed_no_signal(false)
			
	# Slide old HUD out to the side
	if old_panel != null and smooth:
		var tween1 = get_tree().create_tween()
		var shifter1 = old_panel.get_node("Shifter")
		shifter1.offset_left = 0
		shifter1.offset_right = 0
		shifter1.offset_top = 0
		shifter1.offset_bottom = 0
		tween1.tween_property(shifter1, "offset_left", -2000, transition_time).set_trans(Tween.TRANS_SINE)
		tween1.parallel().tween_property(shifter1, "offset_right", -2000, transition_time).set_trans(Tween.TRANS_SINE)
		# Wait for tweening to finish
		await get_tree().create_timer(transition_time).timeout
	
	# Set the correct HUD to be visible
	for p in panels:
		if panels.find(p,0) == i:
			new_panel = p
		else:
			p.visible = false
		
	# Slide new HUD in from the top if sliding
	new_panel.visible = true
	if smooth:
		var tween2 = get_tree().create_tween()
		var shifter2 = new_panel.get_node("Shifter")
		shifter2.offset_top = -2000
		shifter2.offset_bottom = -2000
		shifter2.offset_left = 0
		shifter2.offset_right = 0
		tween2.tween_property(shifter2, "offset_top", 0, transition_time).set_trans(Tween.TRANS_SINE)
		tween2.parallel().tween_property(shifter2, "offset_bottom", 0, transition_time).set_trans(Tween.TRANS_SINE)
	old_panel = new_panel
