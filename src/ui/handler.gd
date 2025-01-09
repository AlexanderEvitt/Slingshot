extends VBoxContainer

var huds
var butts
var h = 0


# Get refs to all the HUDs and buttons
func _ready():
	huds = get_tree().get_nodes_in_group("HUDs")
	butts = get_tree().get_nodes_in_group("Buttons")

func _input(event):
	# Check if player is moving around the view with the shfit key
	var is_shift = Input.is_action_just_pressed("mod_up") or Input.is_action_just_pressed("mod_down") or Input.is_action_just_pressed("mod_left") or Input.is_action_just_pressed("mod_right")
	# Handle arrow keys switching HUD
	if !is_shift:
		if Input.is_action_just_pressed("arrow_up"):
			h = h - 4
		elif Input.is_action_just_pressed("arrow_down"):
			h = h + 4
		elif Input.is_action_just_pressed("arrow_left"):
			h = h - 1
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
	
	# Set the correct HUD to be visible
	for hud in huds:
		if huds.find(hud,0) == i:
			hud.visible = true
		else:
			hud.visible = false


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
