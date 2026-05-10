class_name SpacecraftProxy
extends Proxy

@onready var pointer: Node3D = $Pointer

var ship: PlayerShip = null   # typed shadow of sim_object
var plotter: Plotter = null   # optional child node for trajectory plotting


func set_sim_object(node: Node) -> void:
	super(node)
	ship = node as PlayerShip
	if has_node("Plotter"):
		plotter = $Plotter
	# Claim the CameraRig from the Dynamic node if it's parked there waiting.
	# This always claims the camera when the player spawns
	var parent: Node = get_parent()
	if parent and parent.has_node("CameraRig"):
		var rig: ExternalCameraRig = parent.get_node("CameraRig")
		rig.reparent(self)
		rig.position = Vector3(0,0,0)


func _sync() -> void:
	position = ship.system_position
	pointer.transform.basis = ship.attitude
	if plotter:
		@warning_ignore("unsafe_property_access")
		plotter.positions = ship.propagate_module.get("plotted_positions")
