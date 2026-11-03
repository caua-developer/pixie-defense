extends Path2D

const SPAWN_INTERVAL: float = 2.0  # segundos, hipótese — calibrar na Fase 10

# Proporção fixa de tier nesta fase (sem progressão por dia — balancing.md trata isso só a partir da Fase 7)
# Índices: 0 branco, 1 verde, 2 azul, 3 vermelho
const TIER_WEIGHTS: Array[float] = [60.0, 25.0, 12.0, 3.0]  # hipótese — calibrar na Fase 10

@export var enemy_scene: PackedScene
@export var start_position: Vector2 = Vector2(600, 0)

@onready var spawn_timer: Timer = $SpawnTimer

var golem: Node2D = null

func register_golem(new_golem: Node2D, offset: float) -> void:
	if golem:
		golem.queue_free()
	golem = new_golem
	new_golem.corredor = self
	new_golem.block_distance = offset
	new_golem.position = curve.sample_baked(offset, true)
	add_child(new_golem)

func get_block_distance() -> float:
	return golem.block_distance if golem else INF

func spawn_enemy_with_tier(tier: int) -> void:
	var enemy: Area2D = enemy_scene.instantiate()
	enemy.position = curve.sample_baked(0.0, true)
	get_parent().add_child(enemy)
	enemy.set_tier(tier)
	enemy.set_path_curve(curve)
	enemy.corredor = self

func _ready() -> void:
	add_to_group("corredores")
	var path_curve := Curve2D.new()
	path_curve.add_point(start_position)
	path_curve.add_point(Vector2.ZERO)
	curve = path_curve
	spawn_timer.wait_time = SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	spawn_enemy_with_tier(_pick_tier())

func _pick_tier() -> int:
	var total: float = 0.0
	for weight in TIER_WEIGHTS:
		total += weight
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in TIER_WEIGHTS.size():
		cumulative += TIER_WEIGHTS[i]
		if roll < cumulative:
			return i
	return TIER_WEIGHTS.size() - 1
