extends VBoxContainer

var huds


# Called when the node enters the scene tree for the first time.
func _ready():
	huds = get_tree().get_nodes_in_group("HUDs")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	


func _on_nav_button_pressed():
	set_huds(0)

func _on_con_button_pressed():
	set_huds(1)

func _on_att_button_pressed():
	set_huds(2)
	
func set_huds(i):
	for h in huds:
		if huds.find(h,0) == i:
			h.visible = true
		else:
			h.visible = false
