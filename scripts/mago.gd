extends Node2D

const MAX_MANA: float = 100.0
const MANA_REGEN_PER_SEC: float = 10.0  # hipótese — calibrar na Fase 10
const BASE_SPELL_COST: float = 25.0     # hipótese — calibrar na Fase 10
const BASE_SPELL_COOLDOWN: float = 1.0  # segundos, hipótese — calibrar na Fase 10
const BASE_SPELL_RADIUS: float = 80.0   # px, hipótese — calibrar na Fase 10
const BASE_SPELL_DAMAGE: float = 50.0   # hipótese — calibrar na Fase 10 (mata o inimigo tier branco em 1 acerto)

const DAMAGE_UPGRADE_MULT: float = 1.2    # hipótese — calibrar na Fase 10
const COOLDOWN_UPGRADE_MULT: float = 0.8  # hipótese — calibrar na Fase 10
const MANA_COST_UPGRADE_MULT: float = 0.8 # hipótese — calibrar na Fase 10
const RADIUS_UPGRADE_MULT: float = 1.2    # hipótese — calibrar na Fase 10

@export var spell_effect_scene: PackedScene

var mana: float = MAX_MANA
var cooldown_remaining: float = 0.0
var spell_cost: float = BASE_SPELL_COST
var spell_cooldown: float = BASE_SPELL_COOLDOWN
var spell_radius: float = BASE_SPELL_RADIUS
var spell_damage: float = BASE_SPELL_DAMAGE
var specialization: String = "Destrutiva"

var _has_pending_cast: bool = false
var _pending_cast_position: Vector2

func _ready() -> void:
	add_to_group("mago")

func upgrade_damage() -> void:
	spell_damage *= DAMAGE_UPGRADE_MULT

func reduce_cooldown() -> void:
	spell_cooldown *= COOLDOWN_UPGRADE_MULT

func reduce_mana_cost() -> void:
	spell_cost *= MANA_COST_UPGRADE_MULT

func increase_radius() -> void:
	spell_radius *= RADIUS_UPGRADE_MULT

func _process(delta: float) -> void:
	mana = min(MAX_MANA, mana + MANA_REGEN_PER_SEC * delta)
	cooldown_remaining = max(0.0, cooldown_remaining - delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_spell"):
		_try_cast(get_global_mouse_position())

func _try_cast(target_pos: Vector2) -> void:
	if cooldown_remaining > 0.0 or mana < spell_cost:
		return
	mana -= spell_cost
	cooldown_remaining = spell_cooldown
	_pending_cast_position = target_pos
	_has_pending_cast = true
	_spawn_spell_effect(target_pos)

func _physics_process(_delta: float) -> void:
	if not _has_pending_cast:
		return
	_has_pending_cast = false
	var shape := CircleShape2D.new()
	shape.radius = spell_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, _pending_cast_position)
	query.collision_mask = 2  # layer "inimigos"
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var space_state := get_world_2d().direct_space_state
	for result in space_state.intersect_shape(query):
		var collider = result["collider"]
		if collider.has_method("take_damage"):
			collider.take_damage(spell_damage)

func _spawn_spell_effect(target_pos: Vector2) -> void:
	if spell_effect_scene == null:
		return
	var effect: Node2D = spell_effect_scene.instantiate()
	effect.position = target_pos
	effect.radius = spell_radius
	get_parent().add_child(effect)
