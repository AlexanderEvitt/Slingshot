extends Node3D

# Untyped intentionally: typed Dictionary[Node, Proxy] validates keys/values on access,
# which throws "freed instance" errors when iterating stale entries before we can check them.
var _tracked: Dictionary = {}


func _ready() -> void:
	# Deferred so PlayerShip._ready() has already run and joined the group.
	# This ensures the ship proxy (and camera reparent) happen before the first frame renders.
	call_deferred("_sync")


func _process(_delta: float) -> void:
	_sync()


func _sync() -> void:
	var orbit_scene: OrbitScene = get_parent() as OrbitScene

	for node: Node in get_tree().get_nodes_in_group("Dynamic"):
		if not _tracked.has(node):
			# Must be ignored because we're fetching the same method from different classes
			@warning_ignore("unsafe_method_access")
			var proxy: Proxy = node.get_orbit_rep().instantiate()
			if proxy == null:
				push_error("Orbit rep for '%s' does not extend Proxy." % node.name)
				continue
			add_child(proxy)
			proxy.set_sim_object(node)
			_tracked[node] = proxy

			# Wire up any Selectable Area3D children so clicking them updates selected_node.
			if orbit_scene != null:
				for child: Node in proxy.find_children("*", "Area3D", true, false):
					if child.is_in_group("Selectable"):
						(child as Area3D).input_event.connect(orbit_scene.on_selected.bind(proxy))

	# Cull proxies whose sim object has been freed.
	# Arrays and iteration are untyped here for the same reason as _tracked.
	var stale: Array = []
	@warning_ignore("untyped_declaration")
	for node in _tracked.keys():
		if not is_instance_valid(node):
			stale.append(node)
	@warning_ignore("untyped_declaration")
	for node in stale:
		@warning_ignore("unsafe_cast")
		var dying: Proxy = _tracked[node] as Proxy
		_rescue_transients(dying)
		dying.queue_free()
		_tracked.erase(node)


# Reparent any nodes that were moved into a proxy from outside (e.g. CameraRig, WaypointRig)
# back to a safe home before the proxy is freed. Without this, Godot frees the entire subtree
# and any external references to those nodes become dangling pointers.
func _rescue_transients(proxy: Proxy) -> void:
	var fallback: Node3D = self  # park on Dynamic as a last resort
	# Prefer the spacecraft proxy as the fallback home, since it persists for the session.
	@warning_ignore("untyped_declaration")
	for tracked_proxy in _tracked.values():
		if tracked_proxy is SpacecraftProxy:
			fallback = tracked_proxy
			break
	for child: Node in proxy.get_children():
		# Nodes owned by the proxy were instantiated with it and should be freed with it.
		# Nodes with a different owner were reparented in from elsewhere — rescue those.
		if child.owner != proxy:
			child.reparent(fallback)
