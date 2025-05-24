extends Panel

var calc_status_box


# Called when the node enters the scene tree for the first time.
func _ready():
	calc_status_box = get_node("HBoxContainer/Centerfold/MarginContainer/VBoxContainer/CenterPanel/MarginContainer/CenterPanel/VBoxContainer/ExecutionPanel/VBoxContainer/MarginContainer/CalcStatusBox")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_calculate():
	# Zeroth order estimate of transfer time
	var target = Conversions.FindFrame(SystemTime.t)
	var transfer_dist = target - ShipData.player_ship.position;
	var transfer_time = 2*sqrt(transfer_dist.length()/0.05)
	
	# Calculate properly
	ShipData.propagator.SMC(ShipData.player_ship.position,Conversions.FindFrame(SystemTime.t + transfer_time), ShipData.player_ship.velocity, SystemTime.t)

	# Set the status box to green
	var new_style = StyleBoxFlat.new()
	new_style.bg_color = Color8(51, 255, 51, 255)
	calc_status_box.add_theme_stylebox_override("panel",new_style)
	calc_status_box.get_node("Label").text = "CALCULATED"

func _on_clear():
	ShipData.propagator.ClearPlan()
	
	# Set the status box to red
	var new_style = StyleBoxFlat.new()
	new_style.bg_color = Color8(128, 0, 0, 255)
	calc_status_box.add_theme_stylebox_override("panel",new_style)
	calc_status_box.get_node("Label").text = "NO DATA"
