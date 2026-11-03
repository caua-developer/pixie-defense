extends Node2D

const BASE_MAX_HP: float = 150.0  # hipótese — calibrar na Fase 10

var max_hp: float = BASE_MAX_HP
var hp: float = BASE_MAX_HP
var corredor: Node = null
var block_distance: float = 0.0
var _burned_attackers: Dictionary = {}

func _ready() -> void:
	add_to_group("golems")
	hp = max_hp

func take_damage(amount: float, attacker: Object = null) -> void:
	hp -= amount
	if attacker and corredor:
		var mago: Node = get_tree().get_first_node_in_group("mago")
		if mago and mago.specialization == "Defensiva":
			var attacker_id: int = attacker.get_instance_id()
			var allow_burst: bool = not _burned_attackers.has(attacker_id)
			if allow_burst:
				_burned_attackers[attacker_id] = true
			mago._apply_cross_affixes_to_target(attacker, allow_burst)
	if hp <= 0.0:
		_die()

func _die() -> void:
	if corredor:
		corredor.golem = null
	queue_free()
