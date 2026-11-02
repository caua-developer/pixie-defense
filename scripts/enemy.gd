extends Area2D

const SPEED: float = 80.0           # px/s, hipótese — calibrar na Fase 10
const MAX_HP: float = 50.0          # hipótese — calibrar na Fase 10
const CONTACT_DAMAGE: float = 10.0  # dano à base ao chegar, hipótese — calibrar na Fase 10

var hp: float = MAX_HP
var _curve: Curve2D
var _distance: float = 0.0

func _ready() -> void:
	add_to_group("inimigos")

func set_path_curve(curve: Curve2D) -> void:
	_curve = curve

func _physics_process(delta: float) -> void:
	if _curve == null:
		return
	_distance += SPEED * delta
	if _distance >= _curve.get_baked_length():
		_on_reached_base()
		return
	position = _curve.sample_baked(_distance, true)

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		queue_free()

func _on_reached_base() -> void:
	var base := get_tree().get_first_node_in_group("base")
	if base:
		base.take_damage(CONTACT_DAMAGE)
	queue_free()
