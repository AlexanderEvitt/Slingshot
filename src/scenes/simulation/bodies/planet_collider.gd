extends StaticBody3D

@onready var parent_body: Body = get_parent()

func _phsyics_process(_delta: float) -> void:
	constant_linear_velocity = parent_body.fetch_velocity(SimTime.t) - ShipData.floating_frame_velocity
