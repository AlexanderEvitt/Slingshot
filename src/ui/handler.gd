extends VBoxContainer

var huds
var butts
var h = 0

var old_hud
var new_hud

var transition_time = 0.25


# Get refs to all the HUDs and buttons
func _ready():
	huds = get_tree().get_nodes_in_group("HUDs")
	butts = get_tree().get_nodes_in_group("Buttons")
	
	set_huds(0)

func _input(_event):
	# Check if player is moving around the view with the shift key
	var is_shift = Input.is_action_just_pressed("mod_up") or Input.is_action_just_pressed("mod_down") or Input.is_action_just_pressed("mod_left") or Input.is_action_just_pressed("mod_right")
	# Handle arrow keys switching HUD
	if !is_shift:
		if Input.is_action_just_pressed("arrow_up"):
			h = h - 4
			h = clamp(h,0,7)
			set_huds(h)
		elif Input.is_action_just_pressed("arrow_down"):
			h = h + 4
			h = clamp(h,0,7)
			set_huds(h)
		elif Input.is_action_just_pressed("arrow_left"):
			h = h - 1
			h = clamp(h,0,7)
			set_huds(h)
		elif Input.is_action_just_pressed("arrow_right"):
			h = h + 1
			h = clamp(h,0,7)
			set_huds(h)

func set_huds(i):
	h = i # used for keeping track of which HUD is active
	
	# Set all the buttons to be un-toggled except the one just pressed
	for b in butts:
		if butts.find(b,0) == i:
			b.set_pressed_no_signal(true)
		else:
			b.set_pressed_no_signal(false)
			
	# Slide old HUD out to the side
	if old_hud != null:
		var tween1 = get_tree().create_tween()
		var shifter1 = old_hud.get_node("Shifter")
		shifter1.offset_left = 0
		shifter1.offset_right = 0
		shifter1.offset_top = 0
		shifter1.offset_bottom = 0
		tween1.tween_property(shifter1, "offset_left", -2000, transition_time).set_trans(Tween.TRANS_SINE)
		tween1.parallel().tween_property(shifter1, "offset_right", -2000, transition_time).set_trans(Tween.TRANS_SINE)
		
	await get_tree().create_timer(transition_time).timeout
	
	# Set the correct HUD to be visible
	for hud in huds:
		if huds.find(hud,0) == i:
			new_hud = hud
		else:
			hud.visible = false
		
	# Slide new HUD in from the top
	new_hud.visible = true
	var tween2 = get_tree().create_tween()
	var shifter2 = new_hud.get_node("Shifter")
	shifter2.offset_top = -2000
	shifter2.offset_bottom = -2000
	shifter2.offset_left = 0
	shifter2.offset_right = 0
	tween2.tween_property(shifter2, "offset_top", 0, transition_time).set_trans(Tween.TRANS_SINE)
	tween2.parallel().tween_property(shifter2, "offset_bottom", 0, transition_time).set_trans(Tween.TRANS_SINE)
	old_hud = new_hud
		


func _on_button1_pressed():
	set_huds(0)

func _on_button2_pressed():
	set_huds(1)

func _on_button3_pressed():
	set_huds(2)

func _on_button4_pressed():
	set_huds(3)

func _on_button5_pressed():
	set_huds(4)

func _on_button6_pressed():
	set_huds(5)

func _on_button7_pressed():
	set_huds(6)

func _on_button8_pressed():
	set_huds(7)
