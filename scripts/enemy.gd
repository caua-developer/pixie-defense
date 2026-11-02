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

var hp: float = MAX_HP
var speed: float = SPEED
var contact_damage: float = CONTACT_DAMAGE

var _curve: Curve2D
var _distance: float = 0.0

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	add_to_group("inimigos")

func set_tier(tier: int) -> void:
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
	_distance += speed * delta
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
		base.take_damage(contact_damage)
	queue_free()
