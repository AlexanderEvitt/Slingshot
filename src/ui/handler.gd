extends VBoxContainer

var huds
var butts


# Get refs to all the HUDs and buttons
func _ready():
	huds = get_tree().get_nodes_in_group("HUDs")
	butts = get_tree().get_nodes_in_group("Buttons")


func set_huds(i):
	# Set all the buttons to be un-toggled except the one just pressed
	for b in butts:
		if butts.find(b,0) == i:
			pass
		else:
			b.button_pressed = false
	
	# Set the correct HUD to be visible
	for h in huds:
		if huds.find(h,0) == i:
			h.visible = true
		else:
			h.visible = false


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
