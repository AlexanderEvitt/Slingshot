class_name ShipCameras
extends Resource

# Assign one scene per view slot in the editor.
# Leave a slot null if this ship type has no camera for that view.
@export var first_person: PackedScene
@export var third_person: PackedScene
@export var background: PackedScene
