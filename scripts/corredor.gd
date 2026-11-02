extends Path2D

const SPAWN_INTERVAL: float = 2.0  # segundos, hipótese — calibrar na Fase 10

# Proporção fixa de tier nesta fase (sem progressão por dia — balancing.md trata isso só a partir da Fase 7)
# Índices: 0 branco, 1 verde, 2 azul, 3 vermelho
const TIER_WEIGHTS: Array[float] = [60.0, 25.0, 12.0, 3.0]  # hipótese — calibrar na Fase 10

@export var enemy_scene: PackedScene
@export var start_position: Vector2 = Vector2(600, 0)

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	var path_curve := Curve2D.new()
	path_curve.add_point(start_position)
	path_curve.add_point(Vector2.ZERO)
	curve = path_curve
	spawn_timer.wait_time = SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	var enemy: Area2D = enemy_scene.instantiate()
	enemy.position = curve.sample_baked(0.0, true)
	get_parent().add_child(enemy)
	enemy.set_tier(_pick_tier())
	enemy.set_path_curve(curve)

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
