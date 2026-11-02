extends Path2D

const SPAWN_INTERVAL: float = 2.0  # segundos, hipótese — calibrar na Fase 10

@export var enemy_scene: PackedScene

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.wait_time = SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	var enemy: Area2D = enemy_scene.instantiate()
	enemy.position = curve.sample_baked(0.0, true)
	enemy.set_path_curve(curve)
	get_parent().add_child(enemy)
