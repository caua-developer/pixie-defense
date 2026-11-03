extends Node

const MINI_BOSS_KILL_INTERVAL: int = 20  # hipótese — calibrar na Fase 10
const BOSS_KILL_INTERVAL: int = 50       # hipótese — calibrar na Fase 10
const MINI_BOSS_TIER: int = 4
const BOSS_TIER: int = 5
const MINI_BOSS_ESSENCE: float = 0.5
const BOSS_ESSENCE: float = 1.0
const AFFIX_UNLOCK_THRESHOLD: float = 1.0

var kills: int = 0
var boss_essence: float = 0.0
var affixes_unlocked: int = 0

func _ready() -> void:
	add_to_group("boss_tracker")

func register_kill(tier: int) -> void:
	if tier < MINI_BOSS_TIER:
		kills += 1
		if kills % MINI_BOSS_KILL_INTERVAL == 0:
			_spawn_boss_tier(MINI_BOSS_TIER)
		if kills % BOSS_KILL_INTERVAL == 0:
			_spawn_boss_tier(BOSS_TIER)
	else:
		boss_essence += MINI_BOSS_ESSENCE if tier == MINI_BOSS_TIER else BOSS_ESSENCE
		affixes_unlocked = min(2, int(boss_essence / AFFIX_UNLOCK_THRESHOLD))

func _spawn_boss_tier(tier: int) -> void:
	var corredores := get_tree().get_nodes_in_group("corredores")
	if corredores.is_empty():
		return
	var corredor: Node = corredores[randi() % corredores.size()]
	corredor.spawn_enemy_with_tier(tier)
