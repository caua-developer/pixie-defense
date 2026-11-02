extends Node2D

var radius: float = 80.0

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.one_shot = true
	timer.wait_time = 0.15
	timer.timeout.connect(queue_free)
	timer.start()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.85, 0.85, 1.0, 0.35))
