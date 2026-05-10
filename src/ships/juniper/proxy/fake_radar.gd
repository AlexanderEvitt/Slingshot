extends Node3D

@export var dwell_time: float = 0.5      # seconds spent pointing at each target
@export var slew_duration: float = 0.4   # seconds to rotate between targets
@export var beam_width_deg: float = 10.0 # full cone angle; top radius scales to hold this at target range

@onready var beam_mesh: MeshInstance3D = $MeshInstance3D

enum State { DWELLING, SLEWING }

var _state: State = State.DWELLING
var _index: int = 0
var _timer: float = 0.0
var _from_basis: Basis = Basis.IDENTITY
var _to_basis: Basis = Basis.IDENTITY
var _initialised: bool = false


func _process(delta: float) -> void:
	var threats: Array[Missile] = ShipData.player_ship.defense_module.active_threats

	if threats.is_empty():
		visible = false
		return

	visible = true

	# Clamp index in case the threat list shrank since last frame.
	_index = _index % threats.size()

	# Point at the first target immediately on the first frame threats appear.
	if not _initialised:
		transform.basis = _basis_toward(threats[_index])
		_initialised = true

	match _state:
		State.DWELLING:
			_timer += delta
			if _timer >= dwell_time:
				_timer = 0.0
				_index = (_index + 1) % threats.size()
				_from_basis = transform.basis
				_to_basis = _basis_toward(threats[_index])
				_state = State.SLEWING

		State.SLEWING:
			_timer += delta
			var t: float = clampf(_timer / slew_duration, 0.0, 1.0)
			transform.basis = _from_basis.slerp(_to_basis, t)
			if _timer >= slew_duration:
				transform.basis = _to_basis
				_timer = 0.0
				_state = State.DWELLING

	_update_beam(threats[_index])


func _update_beam(target: Missile) -> void:
	var dist: float = (target.system_position - ShipData.player_ship.system_position).length()
	var cylinder: CylinderMesh = beam_mesh.mesh as CylinderMesh
	cylinder.height = dist
	cylinder.top_radius = dist * tan(deg_to_rad(beam_width_deg * 0.5))
	beam_mesh.position.z = dist * 0.5


# Returns a basis whose +Z axis points from the ship toward the given missile.
func _basis_toward(missile: Missile) -> Basis:
	var dir: Vector3 = (missile.system_position - ShipData.player_ship.system_position).normalized()
	if dir.length_squared() < 0.0001:
		return transform.basis
	var up: Vector3 = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	return Basis.looking_at(dir, up, true)  # use_model_front=true makes +Z face dir
