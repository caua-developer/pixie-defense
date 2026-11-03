extends Area2D

const MAX_HP: float = 50.0          # hipótese — calibrar na Fase 10 (valor base do tier 0)
const SPEED: float = 80.0           # px/s, hipótese — calibrar na Fase 10 (valor base do tier 0)
const CONTACT_DAMAGE: float = 10.0  # dano à base ao chegar, hipótese — calibrar na Fase 10 (valor base do tier 0)

# Índices: 0 branco, 1 verde, 2 azul, 3 vermelho — paleta fixa de design-system.md
const TIER_HP_MULT: Array[float] = [1.0, 1.5, 2.2, 3.5]       # hipótese — calibrar na Fase 10
const TIER_SPEED_MULT: Array[float] = [1.0, 1.0, 1.1, 1.25]   # hipótese — calibrar na Fase 10
const TIER_DAMAGE_MULT: Array[float] = [1.0, 1.2, 1.6, 2.2]   # hipótese — calibrar na Fase 10
const TIER_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0, 1.0),    # branco — cor nativa, tint neutro
	Color(0.25, 0.85, 0.3, 1.0),  # verde — matiz hipotética, calibrar visualmente (design-system.md)
	Color(0.25, 0.55, 0.95, 1.0), # azul — matiz hipotética, calibrar visualmente
	Color(0.9, 0.2, 0.2, 1.0),    # vermelho — matiz hipotética, calibrar visualmente
]
# Índices: 0 branco, 1 verde, 2 azul, 3 vermelho — mesma ordem de TIER_HP_MULT
const FRAGMENT_DROP: Array[int] = [1, 2, 4, 6]  # hipótese — calibrar na Fase 10 (balancing.md)

var hp: float = MAX_HP
var speed: float = SPEED
var contact_damage: float = CONTACT_DAMAGE
var tier: int = 0
var corredor: Node = null
var damage_taken_multiplier: float = 1.0

var _curve: Curve2D
var _distance: float = 0.0
var _curse_time_remaining: float = 0.0
var _slow_multiplier: float = 1.0
var _slow_time_remaining: float = 0.0

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	add_to_group("inimigos")

func set_tier(new_tier: int) -> void:
	tier = new_tier
	hp = MAX_HP * TIER_HP_MULT[tier]
	speed = SPEED * TIER_SPEED_MULT[tier]
	contact_damage = CONTACT_DAMAGE * TIER_DAMAGE_MULT[tier]
	var mat: ShaderMaterial = visual.material
	if mat:
		mat.set_shader_parameter("tint_color", TIER_COLORS[tier])

func set_path_curve(curve: Curve2D) -> void:
	_curve = curve

func _physics_process(delta: float) -> void:
	if _curve == null:
		return
	if _curse_time_remaining > 0.0:
		_curse_time_remaining -= delta
		if _curse_time_remaining <= 0.0:
			damage_taken_multiplier = 1.0
	if _slow_time_remaining > 0.0:
		_slow_time_remaining -= delta
		if _slow_time_remaining <= 0.0:
			_slow_multiplier = 1.0
	var block_dist: float = corredor.get_block_distance() if corredor else INF
	if _distance >= block_dist:
		if corredor.golem:
			corredor.golem.take_damage(contact_damage * delta)
		return
	_distance += speed * _slow_multiplier * delta
	if _distance >= _curve.get_baked_length():
		_on_reached_base()
		return
	position = _curve.sample_baked(_distance, true)

func take_damage(amount: float) -> void:
	hp -= amount * damage_taken_multiplier
	if hp <= 0.0:
		_on_death()
		queue_free()

func apply_curse(multiplier: float, duration: float) -> void:
	damage_taken_multiplier = multiplier
	_curse_time_remaining = duration

func apply_slow(multiplier: float, duration: float) -> void:
	_slow_multiplier = multiplier
	_slow_time_remaining = duration

func _on_death() -> void:
	var tracker := get_tree().get_first_node_in_group("essencia")
	if tracker:
		tracker.add_fragments(FRAGMENT_DROP[tier])

func _on_reached_base() -> void:
	var base := get_tree().get_first_node_in_group("base")
	if base:
		base.take_damage(contact_damage)
	queue_free()
