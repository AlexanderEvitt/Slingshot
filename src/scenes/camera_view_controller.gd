class_name CameraViewController
extends Node

# The shared World3D all camera SubViewports should render into.
const WORLD := preload("res://scenes/simulation/external_world.tres")

@onready var first_person: SubViewport = $FirstPerson
@onready var third_person: SubViewport = $ThirdPerson
@onready var background:   SubViewport = $Background


func _ready() -> void:
	ShipData.camera_holder = self
	# Assign the shared world to every camera viewport so they all see the simulation.
	for vp: SubViewport in [first_person, third_person, background]:
		vp.world_3d = WORLD
	ShipData.ship_ready.connect(_on_ship_ready)
	ShipData.main_menu.connect(_clear_all)


func _on_ship_ready(ship: PlayerShip) -> void:
	if ship.camera_views == null:
		push_warning("CameraViewController: PlayerShip has no camera_views assigned.")
		return
	_clear_all()
	_populate(first_person, ship.camera_views.first_person)
	_populate(third_person, ship.camera_views.third_person)
	_populate(background,   ship.camera_views.background)


func get_slot_texture(slot: String) -> ViewportTexture:
	match slot:
		"first_person": return first_person.get_texture()
		"third_person": return third_person.get_texture()
		"background":   return background.get_texture()
	push_warning("CameraViewController: unknown slot '%s'." % slot)
	return null


func _populate(vp: SubViewport, scene: PackedScene) -> void:
	if scene == null:
		return
	vp.add_child(scene.instantiate())


func _clear_all() -> void:
	for vp: SubViewport in [first_person, third_person, background]:
		for child: Node in vp.get_children():
			child.queue_free()
