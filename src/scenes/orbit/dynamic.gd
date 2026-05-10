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

	# Cull proxies whose sim object has been freed.
	# Arrays and iteration are untyped here for the same reason as _tracked.
	var stale: Array = []
	for node in _tracked.keys():
		if not is_instance_valid(node):
			stale.append(node)
	for node in stale:
		(_tracked[node] as Proxy).queue_free()
		_tracked.erase(node)
