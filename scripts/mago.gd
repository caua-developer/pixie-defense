extends Node2D

const MAX_MANA: float = 100.0
const MANA_REGEN_PER_SEC: float = 10.0  # hipótese — calibrar na Fase 10
const SPELL_COST: float = 25.0          # hipótese — calibrar na Fase 10
const SPELL_COOLDOWN: float = 1.0       # segundos, hipótese — calibrar na Fase 10
const SPELL_RADIUS: float = 80.0        # px, hipótese — calibrar na Fase 10
const SPELL_DAMAGE: float = 50.0        # hipótese — calibrar na Fase 10 (mata o inimigo tier branco em 1 acerto)

@export var spell_effect_scene: PackedScene

var mana: float = MAX_MANA
var cooldown_remaining: float = 0.0

var _has_pending_cast: bool = false
var _pending_cast_position: Vector2

func _process(delta: float) -> void:
	mana = min(MAX_MANA, mana + MANA_REGEN_PER_SEC * delta)
	cooldown_remaining = max(0.0, cooldown_remaining - delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_spell"):
		_try_cast(get_global_mouse_position())

func _try_cast(target_pos: Vector2) -> void:
	if cooldown_remaining > 0.0 or mana < SPELL_COST:
		return
	mana -= SPELL_COST
	cooldown_remaining = SPELL_COOLDOWN
	_pending_cast_position = target_pos
	_has_pending_cast = true
	_spawn_spell_effect(target_pos)

func _physics_process(_delta: float) -> void:
	if not _has_pending_cast:
		return
	_has_pending_cast = false
	var shape := CircleShape2D.new()
	shape.radius = SPELL_RADIUS
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
			collider.take_damage(SPELL_DAMAGE)

func _spawn_spell_effect(target_pos: Vector2) -> void:
	if spell_effect_scene == null:
		return
	var effect: Node2D = spell_effect_scene.instantiate()
	effect.position = target_pos
	effect.radius = SPELL_RADIUS
	get_parent().add_child(effect)
