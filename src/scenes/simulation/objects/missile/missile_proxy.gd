class_name MissileProxy
extends Proxy

@onready var explosion: Explosion = $Explosion
@onready var sprite: Sprite3D = $Sprite3D

var missile: Missile = null  # typed shadow of sim_object


func set_sim_object(node: Node) -> void:
	super(node)
	missile = node as Missile
	missile.detonated.connect(_on_detonated)


func _on_detonated() -> void:
	explosion.trigger()
	sprite.visible = false


func _sync() -> void:
	position = missile.system_position
