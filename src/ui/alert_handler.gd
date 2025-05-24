extends VBoxContainer

func _input(_event):
	if Input.is_action_just_pressed("fire"):
		avi_test()

# Called when the node enters the scene tree for the first time.
func _ready():
	ShipData.player_ship.auto_disc.connect(auto_disc)
	ShipData.player_ship.nav_disc.connect(nav_disc)
	ShipData.player_ship.rel_clamp.connect(rel_clamp)
	ShipData.player_ship.collision.connect(collision)

func auto_disc():
	var new_label = Label.new()
	new_label.label_settings = load("res://ui/themes/caution_label.tres")
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	new_label.text = "AUTO_DISC: Autopilot automatically disconnected. Reverted to manual control."
	add_child(new_label)

func nav_disc():
	var new_label = Label.new()
	new_label.label_settings = load("res://ui/themes/caution_label.tres")
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	new_label.text = "NAV_DISC: Trajectory no longer valid. Navigation mode disconnected."
	add_child(new_label)
	
func avi_test():
	var new_label = Label.new()
	new_label.label_settings = load("res://ui/themes/info_label.tres")
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	new_label.text = "AVI_TEST: Avionics test completed satisfactorily."
	add_child(new_label)

func rel_clamp():
	var new_label = Label.new()
	new_label.label_settings = load("res://ui/themes/info_label.tres")
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	new_label.text = "REL_CLAMP: Docking clamps released. Spacecraft free for maneuvering."
	add_child(new_label)
	
func collision():
	var new_label = Label.new()
	new_label.label_settings = load("res://ui/themes/warning_label.tres")
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	new_label.text = "COLLISION: Collision detected. Damage sustained."
	add_child(new_label)
