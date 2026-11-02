extends Node

signal base_defeated

const MAX_LIFE: float = 100.0  # hipótese, calibrar na Fase 10 (balancing.md não cobre vida da base em número)

var current_life: float = MAX_LIFE

func _ready() -> void:
	add_to_group("base")

func take_damage(amount: float) -> void:
	if current_life <= 0.0:
		return
	current_life = max(0.0, current_life - amount)
	if current_life <= 0.0:
		base_defeated.emit()
