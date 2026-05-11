extends TextureRect

# Assign the camera holder viewport texture
func _ready() -> void:
	texture = ShipData.camera_holder.third_person.get_texture()
