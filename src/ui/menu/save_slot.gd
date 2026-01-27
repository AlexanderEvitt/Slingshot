extends VBoxContainer

@export var slot_button_group : ButtonGroup

# Button that deletes saves
@export var delete_button : Button


func _ready() -> void:
	# Update the save slot times at startup
	update_save_times()
	
	# Pressing the button calls the delete logic
	delete_button.pressed.connect(delete_save)

func update_save_times() -> void:
	var buttons: Array[BaseButton] = slot_button_group.get_buttons()
	for b in buttons:
		# Cast to type that has id as a parameter
		var save_slot_button := b as SaveSlotButton
		
		# Get place to store last modified time
		var label: Label = b.get_node("HBoxContainer/Time")
		
		var filename: String = "user://save%d.save" % [save_slot_button.id]
		if not FileAccess.file_exists(filename):
			label.text = "EMPTY"
		else:
			var last_modified_time := FileAccess.get_modified_time(filename)
			var time_string := Time.get_datetime_string_from_unix_time(last_modified_time)
			label.text = time_string

func delete_save() -> void:
	# Get the currently selected save
	var pressed_button := slot_button_group.get_pressed_button() as SaveSlotButton
	var slot: int = pressed_button.id
	var filename := "user://save%d.save" % [slot]
	# If file exists, move it to trash
	if FileAccess.file_exists(filename):
		OS.move_to_trash(ProjectSettings.globalize_path(filename))
		
	# Recalculate the save times
	update_save_times()
