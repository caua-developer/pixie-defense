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

const MAX_TREE_MANA: float = 100.0
const TREE_MANA_REGEN_PER_SEC: float = 10.0  # hipótese — calibrar na Fase 10
const BASE_TREE_COST: float = 30.0           # hipótese — calibrar na Fase 10
const BASE_TREE_COOLDOWN: float = 3.0        # hipótese — calibrar na Fase 10
const BASE_CURSE_RADIUS: float = 70.0        # px, hipótese — calibrar na Fase 10
const BASE_CURSE_MULT: float = 1.3           # +30% dano recebido, hipótese
const BASE_CURSE_DURATION: float = 4.0       # segundos, hipótese
const TREE_COOLDOWN_UPGRADE_MULT: float = 0.8
const TREE_MANA_COST_UPGRADE_MULT: float = 0.8
const GOLEM_HP_UPGRADE_MULT: float = 1.2
const CURSE_POTENCIA_UPGRADE_MULT: float = 1.2
const CURSE_DURATION_UPGRADE_MULT: float = 1.2
const GUARDIAN_FURY_DAMAGE_MULT: float = 1.15  # hipótese — calibrar na Fase 10

@export var spell_effect_scene: PackedScene

var mana: float = MAX_MANA
var cooldown_remaining: float = 0.0
var spell_cost: float = BASE_SPELL_COST
var spell_cooldown: float = BASE_SPELL_COOLDOWN
var spell_radius: float = BASE_SPELL_RADIUS
var spell_damage: float = BASE_SPELL_DAMAGE
var specialization: String = "Destrutiva"

var tree_mana: float = MAX_TREE_MANA
var tree_cooldown_remaining: float = 0.0
var tree_spell_cost: float = BASE_TREE_COST
var tree_spell_cooldown: float = BASE_TREE_COOLDOWN
var golem_hp_mult: float = 1.0
var curse_potencia_mult: float = 1.0
var curse_duration_mult: float = 1.0
var guardian_fury_unlocked: bool = false

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

func reduce_tree_cooldown() -> void:
	tree_spell_cooldown *= TREE_COOLDOWN_UPGRADE_MULT

func reduce_tree_mana_cost() -> void:
	tree_spell_cost *= TREE_MANA_COST_UPGRADE_MULT

func upgrade_golem_hp() -> void:
	golem_hp_mult *= GOLEM_HP_UPGRADE_MULT

func upgrade_curse_potencia() -> void:
	curse_potencia_mult *= CURSE_POTENCIA_UPGRADE_MULT

func upgrade_curse_duration() -> void:
	curse_duration_mult *= CURSE_DURATION_UPGRADE_MULT

func unlock_guardian_fury() -> void:
	guardian_fury_unlocked = true

func _process(delta: float) -> void:
	mana = min(MAX_MANA, mana + MANA_REGEN_PER_SEC * delta)
	cooldown_remaining = max(0.0, cooldown_remaining - delta)
	tree_mana = min(MAX_TREE_MANA, tree_mana + TREE_MANA_REGEN_PER_SEC * delta)
	tree_cooldown_remaining = max(0.0, tree_cooldown_remaining - delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_spell"):
		_try_cast(get_global_mouse_position())
	elif event.is_action_pressed("cast_tree_ability"):
		_try_cast_tree_ability(get_global_mouse_position())

func _try_cast(target_pos: Vector2) -> void:
	if cooldown_remaining > 0.0 or mana < spell_cost:
		return
	mana -= spell_cost
	cooldown_remaining = spell_cooldown
	_pending_cast_position = target_pos
	_has_pending_cast = true
	_spawn_spell_effect(target_pos)

func _try_cast_tree_ability(target_pos: Vector2) -> void:
	if specialization == "Destrutiva":
		return
	if tree_cooldown_remaining > 0.0 or tree_mana < tree_spell_cost:
		return
	tree_mana -= tree_spell_cost
	tree_cooldown_remaining = tree_spell_cooldown
	if specialization == "Defensiva":
		_cast_golem(target_pos)
	elif specialization == "Maldição":
		_cast_curse(target_pos)

func _cast_golem(target_pos: Vector2) -> void:
	var corredores: Array[Node] = get_tree().get_nodes_in_group("corredores")
	if corredores.is_empty():
		return
	var closest_corredor: Node = corredores[0]
	var closest_offset: float = closest_corredor.curve.get_closest_offset(closest_corredor.to_local(target_pos))
	var closest_dist: float = closest_corredor.curve.sample_baked(closest_offset, true).distance_to(closest_corredor.to_local(target_pos))
	for c in corredores:
		var offset: float = c.curve.get_closest_offset(c.to_local(target_pos))
		var dist: float = c.curve.sample_baked(offset, true).distance_to(c.to_local(target_pos))
		if dist < closest_dist:
			closest_corredor = c
			closest_offset = offset
			closest_dist = dist
	var golem: Node2D = preload("res://scenes/golem.tscn").instantiate()
	golem.max_hp = golem.BASE_MAX_HP * golem_hp_mult
	closest_corredor.register_golem(golem, closest_offset)

func _cast_curse(target_pos: Vector2) -> void:
	var shape := CircleShape2D.new()
	shape.radius = BASE_CURSE_RADIUS
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, target_pos)
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var space_state := get_world_2d().direct_space_state
	for result in space_state.intersect_shape(query):
		var collider: Object = result["collider"]
		if collider.has_method("apply_curse"):
			collider.apply_curse(BASE_CURSE_MULT * curse_potencia_mult, BASE_CURSE_DURATION * curse_duration_mult)

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
		var collider: Object = result["collider"]
		if collider.has_method("take_damage"):
			var damage: float = spell_damage
			if guardian_fury_unlocked and not get_tree().get_nodes_in_group("golems").is_empty():
				damage *= GUARDIAN_FURY_DAMAGE_MULT
			collider.take_damage(damage)

func _spawn_spell_effect(target_pos: Vector2) -> void:
	if spell_effect_scene == null:
		return
	var effect: Node2D = spell_effect_scene.instantiate()
	effect.position = target_pos
	effect.radius = spell_radius
	get_parent().add_child(effect)
