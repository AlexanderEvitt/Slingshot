extends Node3D

@onready var child_emitter1: GPUParticles3D = get_node("GPUParticles3D")
@onready var child_emitter2: GPUParticles3D = get_node("GPUParticles3D2")
@onready var gun : GPUParticles3D = get_node("Gun")
var elapsed_time := 0.0
var fire_count := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	child_emitter1.emitting = false
	child_emitter2.emitting = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("fire"):
		gun.emitting = true
	else:
		gun.emitting = false

	elapsed_time += delta
	if elapsed_time > child_emitter1.lifetime:
		child_emitter1.emitting = false
		child_emitter2.emitting = false
		elapsed_time = 0.0
	
	if Input.is_action_just_released("fire"):
		fire_count += 1
		
		if fire_count > 5:
			fire_count = 0
			child_emitter1.emitting = true
			child_emitter2.emitting = true
			
			# Add torque
			# Kill engine
			ShipData.player_ship.propulsion_module.throttle = 0.0
			
