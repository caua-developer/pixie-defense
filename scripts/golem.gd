extends Node2D

const BASE_MAX_HP: float = 150.0  # hipótese — calibrar na Fase 10

var max_hp: float = BASE_MAX_HP
var hp: float = BASE_MAX_HP
var corredor: Node = null
var block_distance: float = 0.0

func _ready() -> void:
	add_to_group("golems")
	hp = max_hp

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_die()

func _die() -> void:
	if corredor:
		corredor.golem = null
	queue_free()
