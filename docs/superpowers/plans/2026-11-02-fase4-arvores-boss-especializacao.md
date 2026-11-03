# Fase 4 — As 3 Árvores + Especialização + Traço Cruzado de Boss Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de criar/editar qualquer nó ou script Godot, re-consulte o card GodotPrompter pela skill `godot-prompter:*` correspondente (este plano já consultou `input-handling`, `save-load` e `physics-system` — ver decisões abaixo, inclusive onde a arquitetura final diverge delas por simplicidade). `CLAUDE.md` Regra 1 tem precedência sobre qualquer recomendação de abstração maior dessas skills.

**Goal:** Qualquer uma das 3 árvores (Destrutiva, Defensiva, Maldição) pode ser escolhida como especialização principal do save (painel no início, persistida em `user://save.json`); a especializada ganha os 4 nós compráveis (mesma UI/padrão da Fase 3); as outras 2 contribuem 1 afixo fixo cada, destravado ao absorver essência de mini-boss/boss (tier roxo, novo gatilho de spawn por contagem de mortes).

**Architecture:** Generaliza o `skill_tree_panel.gd` da Fase 3 (hoje hardcoded pra Destrutiva) pra ler os nós da árvore ativa (`mago.specialization`) de uma tabela por árvore, mantendo os mesmos arrays paralelos (sem `Resource` genérico — 2º/3º consumidor real agora, não especulação). O mago ganha um segundo input/pipeline de conjuração (mana/cooldown próprios) pra a habilidade nova da árvore escolhida (golem ou maldição) — Destrutiva continua com 1 input só. O golem é lógico, não físico: cada `Corredor` guarda a referência do golem ativo (se houver) e sua distância ao longo da curva; o inimigo, no mesmo loop de avanço por distância já existente, para de avançar quando alcança essa distância e passa a danificar o golem a cada frame, sem CharacterBody2D/NavigationAgent novo (corredores continuam fixos). Um novo `BossTracker` (mesmo padrão de node+grupo do `EssenceTracker`) conta mortes globais pra disparar mini-boss/boss (tiers 4/5 do `enemy.gd` já existente) e acumula essência de boss separada, destravando os 2 afixos cruzados em ordem fixa por árvore. `SaveManager` é um `RefCounted` simples (sem nó de cena) que grava só `specialization_tree` em JSON — infraestrutura mínima, justificada no design doc pelas Fases 5 e 8.

**Tech Stack:** Godot 4.7 (GL Compatibility), GDScript com tipagem estática, edição de cena via MCP `godot` (`add_node`, `save_scene`, `run_project`, `get_debug_output`, `stop_project`) com fallback para `Edit` direto no `.tscn`/`project.godot` nos casos que o MCP não cobre.

**Spec:** `docs/superpowers/specs/2026-11-02-fase4-arvores-boss-especializacao-design.md` (documento de design completo desta fase — executores devem ler os dois).

## Global Constraints

- Godot 4.7, renderer GL Compatibility; GDScript com tipagem estática em todo script novo/modificado.
- Cena principal fixa: `res://scenes/main.tscn`.
- Nenhum valor numérico desta fase é definitivo — todos marcados "hipótese, calibrar na Fase 10", seguindo a convenção já usada nas Fases 1–3.
- **Essência de boss não se mistura com a essência normal/fragmentos** (`balancing.md`/design doc): mini-boss = 0.5 ponto, boss = 1.0 ponto, contador separado no `BossTracker`.
- **Gatilho de boss (decisão do usuário):** a cada 20 mortes (de inimigos tier 0–3) spawna 1 mini-boss (tier 4); a cada 50, 1 boss (tier 5).
- **2 tiers roxos separados (decisão do usuário):** tier 4 (mini-boss) e tier 5 (boss), boss mais forte; boss recebe glow mais intenso no shader que o mini-boss.
- **Input de 2 habilidades (decisão do usuário):** clique esquerdo = magia base do mago (ação `cast_spell`, já existe), clique direito = habilidade da árvore escolhida (nova ação `cast_tree_ability`), mana/cooldown **independentes** entre as duas. Especialização Destrutiva não ganha a 2ª ação (sem 2ª habilidade pra ela nesta fase).
- **Golem (minha decisão de designer):** nunca ataca por iniciativa própria (anti-meta "mago é a única unidade ofensiva"); mira usa a mesma mira de área livre, sempre gasta mana/cooldown, nasce no ponto do corredor mais próximo do clique (`Curve2D.get_closest_offset`), sem conceito de "clique inválido".
- **Debuff de dano da Maldição (minha decisão de designer):** `damage_taken_multiplier: float` direto em `enemy.gd`, aplicado em `take_damage()`; sem sistema de status effect genérico.
- **Afixos cruzados — 6 no total, ordem fixa de destravamento por árvore principal** (ver tabela completa no design doc): a cada 1.0 ponto de essência de boss, destrava o próximo afixo na ordem fixa das colunas (Destrutiva→Defensiva→Maldição, pulando a coluna da árvore principal); máximo 2 afixos por especialização.
- **Save mínimo:** só o campo `specialization_tree`, em `user://save.json`, via `JSON.stringify`/`JSON.parse_string` (não `ConfigFile`/`Resource`, seguindo a skill `save-load`). Escolha com confirmação explícita (botão "Confirmar" separado do clique de seleção).
- Sem framework de teste automatizado (mesma decisão herdada das Fases 1–3): verificação via `run_project` + `get_debug_output` + `godot --headless --check-only --script <arquivo>`, usando `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"`.
- Anti-over-engineering (`CLAUDE.md` Regra 1): sem autoload/EventBus/manager genérico/`Resource` de nó de árvore/NavigationAgent/CharacterBody2D novo. A única generalização nova (tabela de nós por árvore em `skill_tree_panel.gd`) já estava pré-registrada como justificada na Fase 3.
- Escopo travado pelo roadmap/design doc: **fora desta fase** — economia de dinheiro, comerciante etéreo, geração procedural, modos de dificuldade, respec, wave spike formal (Fase 7), qualquer campo de save alem de `specialization_tree`.

## Review Focus

- **Transição golem bloqueando → golem morto não deixa inimigo travado.** Ao golem morrer, `corredor.golem` deve virar `null` imediatamente (antes de `queue_free`), senão o inimigo nunca retoma o avanço. Verificado na Task 2 Step 8.
- **Mana/cooldown da magia base e da habilidade de árvore não se misturam.** Conjurar a habilidade de árvore sem mana não deve consumir/bloquear a magia base e vice-versa. Verificado na Task 3 Step 9.
- **Threshold de boss sobreposto (morte nº 100 dispara mini-boss E boss no mesmo evento) não quebra nem duplica essência.** `register_kill` deve poder incrementar os dois spawns no mesmo kill sem efeito colateral (ex.: spawnar 2 vezes a mesma referência de corredor sem conflito). Verificado na Task 4 Step 7.
- **Comprar o mesmo nó duas vezes em árvores diferentes de save diferentes não é possível trocar de especialização em runtime** — `mago.specialization` só é setado 1x pelo painel inicial ou pelo save carregado; nenhum outro código deve reatribuí-lo. Verificado na Task 1 Step 8 (reabrir o jogo com save existente não deve re-mostrar o painel nem permitir trocar).
- **Afixo cruzado destravado não é perdido ao fechar/reabrir o painel da árvore** (estado vive no `BossTracker`, não no painel) — fechar e reabrir o painel deve continuar mostrando o afixo como destravado. Verificado na Task 6 Step 7.

---

## Task 1: `SaveManager` + painel de escolha de especialização

**Files:**
- Create: `scripts/save_manager.gd`
- Create: `scripts/specialization_select_panel.gd`
- Modify: `scripts/mago.gd`
- Modify: `scripts/main.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Produces: `SaveManager.has_save() -> bool`, `SaveManager.load_specialization() -> String`, `SaveManager.save_specialization(tree_name: String) -> void`; `Mago.specialization: String` (default `"Destrutiva"`); `SpecializationSelectPanel.open(on_chosen: Callable) -> void`. Tasks 2–6 leem `mago.specialization` pra decidir qual habilidade/nós estão ativos.
- Consumes: nenhuma interface de outra task.

- [ ] **Step 1: Criar `scripts/save_manager.gd`**

```gdscript
extends RefCounted

const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_specialization() -> String:
	if not has_save():
		return ""
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or not data.has("specialization_tree"):
		return ""
	return data["specialization_tree"]

func save_specialization(tree_name: String) -> void:
	var data: Dictionary = {"version": SAVE_VERSION, "specialization_tree": tree_name}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
```

Minha decisão (skill `save-load`): `RefCounted`, não `Node` — não precisa de posição na árvore de cena nem de lookup por grupo (só `main.gd` o usa, diretamente). JSON em vez de `ConfigFile`/`Resource`, conforme a seção "Strategy Comparison" da skill (save de jogo, não config; nunca Resource pra dado de save).

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/save_manager.gd`
Expected: sem erro.

- [ ] **Step 3: Adicionar `var specialization: String = "Destrutiva"` em `scripts/mago.gd`**

Adicionar junto das outras `var` de instância, antes de `_has_pending_cast`.

- [ ] **Step 4: Criar `scripts/specialization_select_panel.gd`**

```gdscript
extends PanelContainer

@onready var destrutiva_button: Button = $VBox/DestrutivaButton
@onready var defensiva_button: Button = $VBox/DefensivaButton
@onready var maldicao_button: Button = $VBox/MaldicaoButton
@onready var selection_label: Label = $VBox/SelectionLabel
@onready var confirm_button: Button = $VBox/ConfirmButton

var _selected: String = ""
var _on_chosen: Callable

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	confirm_button.disabled = true
	destrutiva_button.pressed.connect(_select.bind("Destrutiva"))
	defensiva_button.pressed.connect(_select.bind("Defensiva"))
	maldicao_button.pressed.connect(_select.bind("Maldição"))
	confirm_button.pressed.connect(_confirm)

func open(on_chosen: Callable) -> void:
	_on_chosen = on_chosen
	visible = true
	get_tree().paused = true

func _select(tree_name: String) -> void:
	_selected = tree_name
	selection_label.text = "Selecionado: %s" % tree_name
	confirm_button.disabled = false

func _confirm() -> void:
	visible = false
	get_tree().paused = false
	_on_chosen.call(_selected)
```

Minha decisão (design doc exige confirmação explícita antes de travar): seleção e confirmação são 2 cliques separados — o botão "Confirmar" só habilita depois de escolher uma árvore, e só ele dispara `_on_chosen`.

- [ ] **Step 5: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/specialization_select_panel.gd`
Expected: sem erro.

- [ ] **Step 6: Adicionar a estrutura do painel em `scenes/main.tscn` via MCP `add_node`**

Sequência de `add_node`:
- `add_node` (`parentNodePath="root/HUD"`, `nodeType="PanelContainer"`, `nodeName="SpecializationSelectPanel"`).
- `add_node` (`parentNodePath="root/HUD/SpecializationSelectPanel"`, `nodeType="VBoxContainer"`, `nodeName="VBox"`).
- Dentro de `VBox`: `add_node` (`nodeType="Button"`, `nodeName="DestrutivaButton"`, `text="Destrutiva"`), `add_node` (`nodeType="Button"`, `nodeName="DefensivaButton"`, `text="Defensiva"`), `add_node` (`nodeType="Button"`, `nodeName="MaldicaoButton"`, `text="Maldição"`), `add_node` (`nodeType="Label"`, `nodeName="SelectionLabel"`, `text=""`), `add_node` (`nodeType="Button"`, `nodeName="ConfirmButton"`, `text="Confirmar"`).

Via `Edit`, no bloco `[node name="SpecializationSelectPanel" ...]`: adicionar `[ext_resource type="Script" path="res://scripts/specialization_select_panel.gd" id="specialization_select_panel_script"]` no topo e, no nó, `script = ExtResource("specialization_select_panel_script")`, `visible = false`, `layout_mode = 3`, `anchors_preset = 8`, `anchor_left = 0.5`, `anchor_top = 0.5`, `anchor_right = 0.5`, `anchor_bottom = 0.5`, `grow_horizontal = 2`, `grow_vertical = 2`, `custom_minimum_size = Vector2(320, 220)` — mesmo padrão de posicionamento central já usado no `SkillTreePanel` da Fase 3.

- [ ] **Step 7: Salvar cena e ligar tudo em `scripts/main.gd`**

`save_scene` (`scenePath="scenes/main.tscn"`). Em `scripts/main.gd`, adicionar no topo:

```gdscript
const SaveManagerScript = preload("res://scripts/save_manager.gd")

@onready var specialization_panel: PanelContainer = $HUD/SpecializationSelectPanel

var save_manager
```

E em `_ready()`, como primeiras linhas (antes do resto já existente):

```gdscript
save_manager = SaveManagerScript.new()
var existing_specialization: String = save_manager.load_specialization()
if existing_specialization != "":
	mago.specialization = existing_specialization
else:
	specialization_panel.open(_on_specialization_chosen)
```

E adicionar o método:

```gdscript
func _on_specialization_chosen(tree_name: String) -> void:
	mago.specialization = tree_name
	save_manager.save_specialization(tree_name)
```

Verificar sintaxe: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/main.gd` — Expected: sem erro.

- [ ] **Step 8: Verificação manual — escolha, persistência e idempotência (Review Focus)**

Apagar `%APPDATA%\Godot\app_userdata\PixieDefense\save.json` se existir (save de teste anterior). `run_project`: o painel de escolha deve aparecer pausado; clicar em "Defensiva" habilita "Confirmar"; clicar em "Confirmar" fecha o painel, despausa, e `mago.specialization` vira `"Defensiva"` (confirmar lendo o arquivo gerado em `user://save.json` via `FileAccess` ou inspecionando o arquivo direto no disco). `stop_project`. `run_project` de novo: o painel **não** deve aparecer (save já existe), e `mago.specialization` deve carregar `"Defensiva"` direto. `get_debug_output` sem erro em ambos os runs. `stop_project`.

- [ ] **Step 9: Commit**

```bash
git add scripts/save_manager.gd scripts/specialization_select_panel.gd scripts/mago.gd scripts/main.gd scenes/main.tscn
git commit -m "feat: adiciona escolha de especializacao com save minimo em json"
```

---

## Task 2: Golem (Defensiva) — bloqueio lógico de corredor

**Files:**
- Create: `scripts/golem.gd`
- Create: `scenes/golem.tscn`
- Modify: `scripts/corredor.gd`
- Modify: `scripts/enemy.gd`

**Interfaces:**
- Produces: `Golem.max_hp: float`, `Golem.take_damage(amount: float) -> void`, grupo `"golems"`; `Corredor.golem: Node2D` (null se vazio), `Corredor.register_golem(golem: Node2D, offset: float) -> void`, `Corredor.get_block_distance() -> float` (retorna `INF` se sem golem), `Corredor.spawn_enemy_with_tier(tier: int) -> void`. Task 3 usa `register_golem`/`get_closest_offset` pra conjurar; Task 4 usa `spawn_enemy_with_tier`.
- Consumes: nenhuma interface nova de outra task (usa `enemy_scene` já exportado em `corredor.gd`).

- [ ] **Step 1: Criar `scripts/golem.gd`**

```gdscript
extends Node2D

const BASE_MAX_HP: float = 150.0  # hipótese — calibrar na Fase 10

var max_hp: float = BASE_MAX_HP
var hp: float = BASE_MAX_HP
var corredor: Node = null
var block_distance: float = 0.0

func _ready() -> void:
	add_to_group("golems")
	hp = max_hp

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_die()

func _die() -> void:
	if corredor:
		corredor.golem = null
	queue_free()
```

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/golem.gd`
Expected: sem erro.

- [ ] **Step 3: Criar `scenes/golem.tscn` via MCP `create_scene` + `add_node`**

`create_scene` (`scenePath="scenes/golem.tscn"`, `rootNodeType="Node2D"`, `rootNodeName="root"`). `add_node` (`parentNodePath="root"`, `nodeType="Polygon2D"`, `nodeName="Visual"`). Via `Edit`, no `Visual`: `color = Color(0.5, 0.4, 0.3, 1)` (tom pedra/madeira, placeholder visual — minha decisão, nenhum asset de golem ainda escolhido) e `polygon = PackedVector2Array(-14, -14, 14, -14, 14, 14, -14, 14)` (mesmo padrão de placeholder quadrado já usado em `Mago`/`enemy.tscn`). No nó raiz: `script = ExtResource("golem_script")` com `[ext_resource type="Script" path="res://scripts/golem.gd" id="golem_script"]` no topo. `save_scene`.

- [ ] **Step 4: Modificar `scripts/corredor.gd` — grupo, registro de golem e bloqueio**

Adicionar em `_ready()`, como primeira linha: `add_to_group("corredores")`.

Adicionar após as `const`/`@export` existentes:

```gdscript
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
```

Minha decisão: `spawn_enemy_with_tier` fatora a lógica já duplicada de `_on_spawn_timer_timeout` (mesma sequência, tier explícito em vez de sorteado) — reaproveitado pela Task 4 pro spawn de mini-boss/boss, sem precisar de uma segunda cena/corredor especial. Atualizar `_on_spawn_timer_timeout` pra chamar `spawn_enemy_with_tier(_pick_tier())` em vez de repetir o corpo.

- [ ] **Step 5: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/corredor.gd`
Expected: sem erro.

- [ ] **Step 6: Modificar `scripts/enemy.gd` — referência ao corredor e lógica de bloqueio**

Adicionar `var corredor: Node = null` junto das outras `var` de instância (setado externamente por quem spawna — Task 4/`corredor.gd` já fazem isso em `spawn_enemy_with_tier`; `corredor.gd._on_spawn_timer_timeout` deve setar `enemy.corredor = self` também, já incluso no Step 4 acima via `spawn_enemy_with_tier`).

Reescrever `_physics_process`:

```gdscript
func _physics_process(delta: float) -> void:
	if _curve == null:
		return
	var block_dist: float = corredor.get_block_distance() if corredor else INF
	if _distance >= block_dist:
		if corredor.golem:
			corredor.golem.take_damage(contact_damage * delta)
		return
	_distance += speed * delta
	if _distance >= _curve.get_baked_length():
		_on_reached_base()
		return
	position = _curve.sample_baked(_distance, true)
```

Minha decisão (skill `physics-system`/`ai-navigation` consultadas — descartado NavigationAgent/CharacterBody2D por serem overkill pra corredor fixo): bloqueio é puramente lógico via distância acumulada, reaproveitando o mesmo padrão de avanço por `Curve2D` já existente desde a Fase 1, sem física nova. Dano ao golem é contínuo (`contact_damage * delta`), não por timer de ataque — mais simples, sem Timer novo por inimigo.

- [ ] **Step 7: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/enemy.gd`
Expected: sem erro.

- [ ] **Step 8: Verificação manual temporária — golem bloqueia, morre, inimigo retoma (Review Focus)**

Adicionar temporariamente ao final de `_ready()` em `scripts/main.gd`: `var test_golem = load("res://scenes/golem.tscn").instantiate(); $Corredor1.register_golem(test_golem, 300.0)`. `run_project`: observar que inimigos do Corredor1 avançam até a posição do golem e param (visualmente sobrepostos/parados no ponto), enquanto Corredor2/Corredor3 seguem normais. Deixar um inimigo bater no golem até ele morrer (HP 150 ÷ `contact_damage` do tier branco (10/s) ≈ 15s) e confirmar que o próximo inimigo do Corredor1 passa direto sem parar. `get_debug_output` sem erro. `stop_project`. Remover a linha temporária de `main.gd` antes do próximo step.

- [ ] **Step 9: Commit**

```bash
git add scripts/golem.gd scenes/golem.tscn scripts/corredor.gd scripts/enemy.gd
git commit -m "feat: adiciona golem com bloqueio logico de corredor"
```

---

## Task 3: Segundo input do mago — habilidade da árvore (golem ou maldição) + debuff no inimigo

**Files:**
- Modify: `project.godot`
- Modify: `scripts/mago.gd`
- Modify: `scripts/enemy.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`

**Interfaces:**
- Produces: `Mago.tree_mana/tree_cooldown_remaining/tree_spell_cost/tree_spell_cooldown`, `Mago.reduce_tree_cooldown() -> void`, `Mago.reduce_tree_mana_cost() -> void`, `Mago.upgrade_golem_hp() -> void`, `Mago.golem_hp_mult: float`, `Mago.upgrade_curse_potencia() -> void`, `Mago.upgrade_curse_duration() -> void`, `Mago.unlock_guardian_fury() -> void`; `Enemy.apply_curse(multiplier: float, duration: float) -> void`, `Enemy.apply_slow(multiplier: float, duration: float) -> void`, `Enemy.damage_taken_multiplier: float`. Task 5 (afixos) e Task 6 (painel) consomem esses métodos/vars.
- Consumes: `Corredor.register_golem`/`get_closest_offset` da Task 2; grupo `"corredores"` (Task 2); `Mago.specialization` (Task 1).

- [ ] **Step 1: Adicionar a ação `cast_tree_ability` em `project.godot`**

Via `Edit`, no bloco `[input]`, após o bloco de `cast_spell`, adicionar:

```
cast_tree_ability={
"deadzone": 0.2,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":2,"canceled":false,"pressed":false,"double_click":false,"script":null)
]
}
```

Minha decisão (skill `input-handling`, seção "Recommended Action Names"): nome de ação descritivo (`cast_tree_ability`), não `right_click` — `button_index=2` é clique direito.

- [ ] **Step 2: Adicionar consts/vars da habilidade de árvore em `scripts/mago.gd`**

Após as consts/vars já existentes:

```gdscript
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

var tree_mana: float = MAX_TREE_MANA
var tree_cooldown_remaining: float = 0.0
var tree_spell_cost: float = BASE_TREE_COST
var tree_spell_cooldown: float = BASE_TREE_COOLDOWN
var golem_hp_mult: float = 1.0
var curse_potencia_mult: float = 1.0
var curse_duration_mult: float = 1.0
var guardian_fury_unlocked: bool = false
```

E os métodos de upgrade:

```gdscript
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
```

Minha decisão: `reduce_tree_cooldown`/`reduce_tree_mana_cost` são genéricos (não sabem se a árvore ativa é Defensiva ou Maldição) — só existe 1 habilidade de árvore ativa por vez (a da especialização), então não há ambiguidade.

- [ ] **Step 3: Atualizar `_process` e `_unhandled_input` em `scripts/mago.gd`**

Em `_process`, adicionar regen da mana de árvore:

```gdscript
tree_mana = min(MAX_TREE_MANA, tree_mana + TREE_MANA_REGEN_PER_SEC * delta)
tree_cooldown_remaining = max(0.0, tree_cooldown_remaining - delta)
```

Reescrever `_unhandled_input`:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cast_spell"):
		_try_cast(get_global_mouse_position())
	elif event.is_action_pressed("cast_tree_ability"):
		_try_cast_tree_ability(get_global_mouse_position())
```

- [ ] **Step 4: Implementar `_try_cast_tree_ability` em `scripts/mago.gd`**

```gdscript
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
	var corredores := get_tree().get_nodes_in_group("corredores")
	if corredores.is_empty():
		return
	var closest_corredor = corredores[0]
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
		var collider = result["collider"]
		if collider.has_method("apply_curse"):
			collider.apply_curse(BASE_CURSE_MULT * curse_potencia_mult, BASE_CURSE_DURATION * curse_duration_mult)
```

Minha decisão: `_cast_golem` acha o corredor mais próximo comparando a distância do ponto mais próximo em cada curva ao clique (varre todos os corredores — só existem 3, custo irrelevante). `_cast_curse` reaproveita exatamente a mesma query de `_physics_process`/`_try_cast` já existente pra consistência de mira entre as 3 árvores, mas chama `apply_curse` em vez de `take_damage`.

- [ ] **Step 5: Verificar sintaxe de `scripts/mago.gd`**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/mago.gd`
Expected: sem erro.

- [ ] **Step 6: Adicionar `apply_curse`/`apply_slow`/`damage_taken_multiplier` e Fúria do Guardião em `scripts/enemy.gd`**

Adicionar vars:

```gdscript
var damage_taken_multiplier: float = 1.0
var _curse_time_remaining: float = 0.0
var _slow_multiplier: float = 1.0
var _slow_time_remaining: float = 0.0
```

Reescrever `take_damage`:

```gdscript
func take_damage(amount: float) -> void:
	hp -= amount * damage_taken_multiplier
	if hp <= 0.0:
		_on_death()
		queue_free()
```

(Renomear `_drop_fragments` para `_on_death` nesta mesma edição — a Task 4 adiciona a chamada ao `BossTracker` dentro dele.)

Adicionar:

```gdscript
func apply_curse(multiplier: float, duration: float) -> void:
	damage_taken_multiplier = multiplier
	_curse_time_remaining = duration

func apply_slow(multiplier: float, duration: float) -> void:
	_slow_multiplier = multiplier
	_slow_time_remaining = duration
```

No topo de `_physics_process`, antes do bloqueio de golem, adicionar a atualização dos timers e o uso do slow no avanço:

```gdscript
if _curse_time_remaining > 0.0:
	_curse_time_remaining -= delta
	if _curse_time_remaining <= 0.0:
		damage_taken_multiplier = 1.0
if _slow_time_remaining > 0.0:
	_slow_time_remaining -= delta
	if _slow_time_remaining <= 0.0:
		_slow_multiplier = 1.0
```

E trocar `_distance += speed * delta` por `_distance += speed * _slow_multiplier * delta`.

- [ ] **Step 7: Aplicar Fúria do Guardião no dano da magia base (`scripts/mago.gd`)**

Em `_physics_process`, dentro do loop de `intersect_shape` de `_try_cast`'s pending cast (o bloco que já existe pra magia base), trocar `collider.take_damage(spell_damage)` por:

```gdscript
var damage: float = spell_damage
if guardian_fury_unlocked and not get_tree().get_nodes_in_group("golems").is_empty():
	damage *= GUARDIAN_FURY_DAMAGE_MULT
collider.take_damage(damage)
```

- [ ] **Step 8: Adicionar `TreeManaLabel` na HUD pra tornar mana/cooldown de árvore observáveis**

`add_node` (`parentNodePath="root/HUD/Root/VBox"`, `nodeType="Label"`, `nodeName="TreeManaLabel"`). Via `Edit`, `text = "Mana de Árvore: 100/100"`. `save_scene`.

Em `scripts/main.gd`, adicionar `@onready var tree_mana_label: Label = $HUD/Root/VBox/TreeManaLabel` e, em `_process`, `tree_mana_label.text = "Mana de Árvore: %d/%d" % [int(mago.tree_mana), int(mago.MAX_TREE_MANA)]`.

- [ ] **Step 9: Verificar sintaxe e verificação manual — mana/cooldown independentes (Review Focus)**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/enemy.gd` e `--script scripts/main.gd` — Expected: sem erro em nenhum. `run_project` com especialização Defensiva (apagar save anterior, escolher Defensiva no painel): clicar repetidamente com o botão esquerdo até a mana base esgotar — confirmar que o clique direito (habilidade de árvore) ainda consegue conjurar um golem normalmente (mana de árvore cheia, independente). Inverter: gastar toda a mana de árvore invocando golems, confirmar que o clique esquerdo ainda conjura a magia base. `get_debug_output` sem erro. `stop_project`. Repetir rapidamente com especialização Maldição (apagar save, escolher Maldição): clique direito deve aplicar o debuff num inimigo no raio (observável pela queda mais rápida de HP nas próximas magias base que o acertarem — sem HUD de debuff ainda, só visual/indireto). `stop_project`.

- [ ] **Step 10: Commit**

```bash
git add project.godot scripts/mago.gd scripts/enemy.gd scenes/main.tscn scripts/main.gd
git commit -m "feat: adiciona segundo input de magia (golem/maldicao) com mana e cooldown independentes"
```

---

## Task 4: `BossTracker` — mini-boss/boss (tiers 4/5), gatilho por contagem de mortes, essência de boss

**Files:**
- Create: `scripts/boss_tracker.gd`
- Modify: `scripts/enemy.gd`
- Modify: `shaders/enemy_tint.gdshader`
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`

**Interfaces:**
- Produces: `BossTracker.register_kill(tier: int) -> void`, `BossTracker.boss_essence: float`, `BossTracker.affixes_unlocked: int` (0–2), grupo `"boss_tracker"`. Task 5 (afixos) e Task 6 (painel) leem `boss_essence`/`affixes_unlocked`.
- Consumes: grupo `"corredores"` e `Corredor.spawn_enemy_with_tier` (Task 2).

- [ ] **Step 1: Criar `scripts/boss_tracker.gd`**

```gdscript
extends Node

const MINI_BOSS_KILL_INTERVAL: int = 20  # hipótese — calibrar na Fase 10
const BOSS_KILL_INTERVAL: int = 50       # hipótese — calibrar na Fase 10
const MINI_BOSS_TIER: int = 4
const BOSS_TIER: int = 5
const MINI_BOSS_ESSENCE: float = 0.5
const BOSS_ESSENCE: float = 1.0
const AFFIX_UNLOCK_THRESHOLD: float = 1.0

var kills: int = 0
var boss_essence: float = 0.0
var affixes_unlocked: int = 0

func _ready() -> void:
	add_to_group("boss_tracker")

func register_kill(tier: int) -> void:
	if tier < MINI_BOSS_TIER:
		kills += 1
		if kills % MINI_BOSS_KILL_INTERVAL == 0:
			_spawn_boss_tier(MINI_BOSS_TIER)
		if kills % BOSS_KILL_INTERVAL == 0:
			_spawn_boss_tier(BOSS_TIER)
	else:
		boss_essence += MINI_BOSS_ESSENCE if tier == MINI_BOSS_TIER else BOSS_ESSENCE
		affixes_unlocked = min(2, int(boss_essence / AFFIX_UNLOCK_THRESHOLD))

func _spawn_boss_tier(tier: int) -> void:
	var corredores := get_tree().get_nodes_in_group("corredores")
	if corredores.is_empty():
		return
	var corredor = corredores[randi() % corredores.size()]
	corredor.spawn_enemy_with_tier(tier)
```

Minha decisão (Review Focus — morte nº 100 dispara os 2 spawns): os 2 `if` são independentes (não `elif`), então kills múltiplos de 20 e 50 ao mesmo tempo (ex. 100) spawnam mini-boss E boss no mesmo evento sem conflito — cada chamada de `_spawn_boss_tier` sorteia seu próprio corredor e instancia um inimigo independente.

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/boss_tracker.gd`
Expected: sem erro.

- [ ] **Step 3: Estender os arrays de tier e `_on_death` em `scripts/enemy.gd`**

Estender os arrays (índices 4 = mini-boss, 5 = boss):

```gdscript
const TIER_HP_MULT: Array[float] = [1.0, 1.5, 2.2, 3.5, 8.0, 20.0]       # hipótese — calibrar na Fase 10
const TIER_SPEED_MULT: Array[float] = [1.0, 1.0, 1.1, 1.25, 0.9, 0.8]    # hipótese — calibrar na Fase 10
const TIER_DAMAGE_MULT: Array[float] = [1.0, 1.2, 1.6, 2.2, 3.0, 4.5]    # hipótese — calibrar na Fase 10
const TIER_GLOW: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.3, 0.6]           # hipótese — só mini-boss(4)/boss(5)
const TIER_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0, 1.0),
	Color(0.25, 0.85, 0.3, 1.0),
	Color(0.25, 0.55, 0.95, 1.0),
	Color(0.9, 0.2, 0.2, 1.0),
	Color(0.6, 0.15, 0.75, 1.0),  # roxo — mini-boss e boss compartilham a cor, glow diferencia
	Color(0.6, 0.15, 0.75, 1.0),  # roxo — boss
]
```

Em `set_tier`, adicionar após a linha de `tint_color`: `mat.set_shader_parameter("glow_strength", TIER_GLOW[tier])`.

`_on_death` já existe (renomeada de `_drop_fragments` na Task 3 Step 6) — substituir o corpo inteiro da função por:

```gdscript
func _on_death() -> void:
	var boss_tracker := get_tree().get_first_node_in_group("boss_tracker")
	if boss_tracker:
		boss_tracker.register_kill(tier)
	if tier < 4:
		var tracker := get_tree().get_first_node_in_group("essencia")
		if tracker:
			tracker.add_fragments(FRAGMENT_DROP[tier])
```

- [ ] **Step 4: Adicionar `glow_strength` em `shaders/enemy_tint.gdshader`**

```glsl
shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR *= tint_color;
	if (glow_strength > 0.0) {
		float pulse = (sin(TIME * 4.0) * 0.5 + 0.5) * glow_strength;
		COLOR.rgb += pulse;
	}
}
```

Minha decisão (`design-system.md`, candidato "glow pulsante" já sugerido, não travado): pulso aditivo simples via `sin(TIME)`, sem textura nova. Boss (`glow_strength=0.6`) fica visivelmente mais intenso que mini-boss (`0.3`).

- [ ] **Step 5: Verificar sintaxe de `scripts/enemy.gd`**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/enemy.gd`
Expected: sem erro.

- [ ] **Step 6: Adicionar nó `BossTracker` em `scenes/main.tscn` e expor label na HUD**

`add_node` (`parentNodePath="root"`, `nodeType="Node"`, `nodeName="BossTracker"`). Via `Edit`: `[ext_resource type="Script" path="res://scripts/boss_tracker.gd" id="boss_tracker_script"]` e `script = ExtResource("boss_tracker_script")` no nó. `add_node` (`parentNodePath="root/HUD/Root/VBox"`, `nodeType="Label"`, `nodeName="BossEssenceLabel"`, `text="Essência de Boss: 0.0/2 afixos"`). `save_scene`.

Em `scripts/main.gd`, adicionar:

```gdscript
@onready var boss_tracker: Node = $BossTracker
@onready var boss_essence_label: Label = $HUD/Root/VBox/BossEssenceLabel
```

E em `_process`, adicionar: `boss_essence_label.text = "Essência de Boss: %.1f (%d/2 afixos)" % [boss_tracker.boss_essence, boss_tracker.affixes_unlocked]`.

Verificar sintaxe: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/main.gd` — Expected: sem erro.

- [ ] **Step 7: Verificação manual — spawn por contagem, essência de boss não mistura, threshold duplo (Review Focus)**

`run_project`. Matar 20 inimigos tier branco (1 clique cada, raio pode acertar mais de 1 por vez — contar pelas mortes reais, não cliques) e confirmar visualmente o spawn de 1 inimigo roxo com glow fraco (mini-boss) num dos 3 corredores; `BossEssenceLabel` deve subir pra "0.5". Continuar até 50 mortes totais e confirmar spawn de um roxo com glow mais forte (boss); `BossEssenceLabel` deve subir pra "1.5" (0.5 do mini-boss + 1.0 do boss, se ambos já tiverem sido mortos) ou refletir corretamente conforme a ordem em que forem abatidos. Confirmar que `EssenceLabel` (fragmentos normais) **não** muda ao matar o mini-boss/boss (essência de boss é separada). `get_debug_output` sem erro. `stop_project`.

- [ ] **Step 8: Commit**

```bash
git add scripts/boss_tracker.gd scripts/enemy.gd shaders/enemy_tint.gdshader scenes/main.tscn scripts/main.gd
git commit -m "feat: adiciona boss tracker com tiers 4/5 e gatilho por contagem de mortes"
```

---

## Task 5: Afixos cruzados (triângulo de 6, aplicados em combate)

**Files:**
- Modify: `scripts/mago.gd`
- Modify: `scripts/golem.gd`

**Interfaces:**
- Produces: `Mago.get_unlocked_cross_affixes() -> Array[int]` (valores do enum `AffixFlavor`); aplica os afixos nos 3 pontos de uso (magia base, cast de maldição, ataque ao golem).
- Consumes: `BossTracker.affixes_unlocked` (Task 4, via grupo `"boss_tracker"`); `Mago.specialization` (Task 1); `Enemy.apply_slow`/`apply_curse`/`take_damage` (Task 2/3).

- [ ] **Step 1: Adicionar enum e tabela de ordem em `scripts/mago.gd`**

No topo do arquivo, antes das consts:

```gdscript
enum AffixFlavor { FIRE_BURST, SLOW, DOT }

const CROSS_AFFIX_ORDER: Dictionary = {
	"Destrutiva": [AffixFlavor.SLOW, AffixFlavor.DOT],
	"Defensiva": [AffixFlavor.FIRE_BURST, AffixFlavor.DOT],
	"Maldição": [AffixFlavor.FIRE_BURST, AffixFlavor.SLOW],
}

const AFFIX_SLOW_MULT: float = 0.5     # hipótese — calibrar na Fase 10
const AFFIX_SLOW_DURATION: float = 2.0 # segundos, hipótese
const AFFIX_DOT_DPS: float = 5.0       # hipótese
const AFFIX_DOT_DURATION: float = 3.0  # segundos, hipótese
const AFFIX_FIRE_BURST_DAMAGE: float = 20.0  # hipótese
```

Minha decisão (design doc, "ordem fixa: segue a ordem das colunas... pulando a coluna da árvore principal"): a tabela já lista só os 2 afixos relevantes por especialização, na ordem de destravamento — índice 0 destrava com 1º ponto de essência de boss, índice 1 com o 2º.

- [ ] **Step 2: Adicionar `apply_dot` em `scripts/enemy.gd`**

Adicionar vars `_dot_dps: float = 0.0` e `_dot_time_remaining: float = 0.0`, método:

```gdscript
func apply_dot(dps: float, duration: float) -> void:
	_dot_dps = dps
	_dot_time_remaining = duration
```

E no `_physics_process`, junto dos outros timers (curse/slow), adicionar:

```gdscript
if _dot_time_remaining > 0.0:
	_dot_time_remaining -= delta
	take_damage(_dot_dps * delta)
```

Verificar sintaxe: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/enemy.gd` — Expected: sem erro.

- [ ] **Step 3: Adicionar `get_unlocked_cross_affixes` e `_apply_cross_affixes_to_target` em `scripts/mago.gd`**

```gdscript
func get_unlocked_cross_affixes() -> Array:
	var boss_tracker := get_tree().get_first_node_in_group("boss_tracker")
	if boss_tracker == null:
		return []
	var order: Array = CROSS_AFFIX_ORDER[specialization]
	return order.slice(0, boss_tracker.affixes_unlocked)

func _apply_cross_affixes_to_target(target) -> void:
	for flavor in get_unlocked_cross_affixes():
		match flavor:
			AffixFlavor.SLOW:
				target.apply_slow(AFFIX_SLOW_MULT, AFFIX_SLOW_DURATION)
			AffixFlavor.DOT:
				target.apply_dot(AFFIX_DOT_DPS, AFFIX_DOT_DURATION)
			AffixFlavor.FIRE_BURST:
				target.take_damage(AFFIX_FIRE_BURST_DAMAGE)
```

- [ ] **Step 4: Aplicar nos 3 pontos de uso**

Em `scripts/mago.gd`, dentro do loop de `intersect_shape` da magia base (`_physics_process`, logo após `collider.take_damage(damage)` do Task 3 Step 7): adicionar `if specialization == "Destrutiva": _apply_cross_affixes_to_target(collider)`.

Dentro de `_cast_curse` (logo após `collider.apply_curse(...)`): adicionar `if specialization == "Maldição": _apply_cross_affixes_to_target(collider)`.

Em `scripts/golem.gd`, modificar `take_damage` pra receber quem bateu e aplicar os afixos de Defensiva:

```gdscript
func take_damage(amount: float, attacker = null) -> void:
	hp -= amount
	if attacker and corredor:
		var mago := get_tree().get_first_node_in_group("mago")
		if mago and mago.specialization == "Defensiva":
			mago._apply_cross_affixes_to_target(attacker)
	if hp <= 0.0:
		_die()
```

E em `scripts/enemy.gd`, no bloco de bloqueio do golem (Task 2 Step 6), passar `self` como atacante: `corredor.golem.take_damage(contact_damage * delta, self)`.

- [ ] **Step 5: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/mago.gd` e `--script scripts/golem.gd` e `--script scripts/enemy.gd`
Expected: sem erro em nenhum.

- [ ] **Step 6: Verificação manual — afixo aplica só depois de destravado, e só os 2 certos pra cada especialização**

`run_project` com especialização Destrutiva (apagar save, escolher Destrutiva). Sem essência de boss ainda, confirmar que acertar um inimigo com a magia base não aplica lentidão nem DoT visível (inimigo morre no ritmo normal). Forçar `boss_tracker.affixes_unlocked = 1` temporariamente via `get_debug_output`/print ou editando `boss_tracker.gd` por 1 verificação (reverter depois) e confirmar que agora a magia base aplica lentidão (Defensiva é a 1ª coluna não-principal pra Destrutiva). Com `affixes_unlocked = 2`, confirmar que também aplica DoT (dano residual visível no HP mesmo sem novos acertos). `get_debug_output` sem erro. `stop_project`.

- [ ] **Step 7: Commit**

```bash
git add scripts/mago.gd scripts/golem.gd scripts/enemy.gd
git commit -m "feat: adiciona sistema de afixos cruzados destravados por essencia de boss"
```

---

## Task 6: Generalizar `skill_tree_panel.gd` pras 3 árvores + exibir afixos cruzados

**Files:**
- Modify: `scripts/skill_tree_panel.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: `Mago.specialization` (Task 1); `Mago.reduce_tree_cooldown/reduce_tree_mana_cost/upgrade_golem_hp/upgrade_curse_potencia/upgrade_curse_duration/unlock_guardian_fury` (Task 3); `BossTracker.affixes_unlocked` (Task 4); `Mago.CROSS_AFFIX_ORDER` (Task 5).
- Produces: nenhuma interface nova (é o fim da cadeia de consumo desta fase).

- [ ] **Step 1: Substituir os arrays fixos de nome/custo por tabela por árvore em `scripts/skill_tree_panel.gd`**

Trocar `NODE_NAMES` por:

```gdscript
const TREE_NODE_NAMES: Dictionary = {
	"Destrutiva": ["Dano+", "Cooldown-", "Custo de Mana-", "Raio+"],
	"Defensiva": ["Golem HP+", "Golem Cooldown-", "Golem Custo de Mana-", "Fúria do Guardião"],
	"Maldição": ["Potência+", "Duração+", "Cooldown-", "Custo de Mana-"],
}
const AFFIX_FLAVOR_NAMES: Dictionary = {
	0: "Estouro de Fogo", # AffixFlavor.FIRE_BURST
	1: "Lentidão",        # AffixFlavor.SLOW
	2: "Dano Contínuo",   # AffixFlavor.DOT
}
```

(`NODE_COSTS` continua igual — `[1, 2, 3, 4]`, compartilhado pelas 3 árvores.)

- [ ] **Step 2: Atualizar `_on_node_pressed` com `match` por especialização**

```gdscript
func _on_node_pressed(index: int) -> void:
	_ensure_refs()
	if purchased[index] or essence_tracker.essence < NODE_COSTS[index]:
		return
	essence_tracker.essence -= NODE_COSTS[index]
	purchased[index] = true
	match mago.specialization:
		"Destrutiva":
			match index:
				0: mago.upgrade_damage()
				1: mago.reduce_cooldown()
				2: mago.reduce_mana_cost()
				3: mago.increase_radius()
		"Defensiva":
			match index:
				0: mago.upgrade_golem_hp()
				1: mago.reduce_tree_cooldown()
				2: mago.reduce_tree_mana_cost()
				3: mago.unlock_guardian_fury()
		"Maldição":
			match index:
				0: mago.upgrade_curse_potencia()
				1: mago.upgrade_curse_duration()
				2: mago.reduce_tree_cooldown()
				3: mago.reduce_tree_mana_cost()
	_update_labels()
```

- [ ] **Step 3: Atualizar `_update_labels` pra ler da árvore ativa e mostrar afixos cruzados**

```gdscript
func _update_labels() -> void:
	balance_label.text = "Essência disponível: %d" % essence_tracker.essence
	var names: Array = TREE_NODE_NAMES[mago.specialization]
	for i in NODE_COUNT:
		var status: String = "comprado" if purchased[i] else "%d essência(s)" % NODE_COSTS[i]
		node_labels[i].text = "%s — %s" % [names[i], status]
		node_buttons[i].disabled = purchased[i]
	var boss_tracker := get_tree().get_first_node_in_group("boss_tracker")
	var unlocked: int = boss_tracker.affixes_unlocked if boss_tracker else 0
	var order: Array = mago.CROSS_AFFIX_ORDER[mago.specialization]
	for i in 2:
		var flavor_name: String = AFFIX_FLAVOR_NAMES[order[i]]
		var status: String = "destravado" if i < unlocked else "bloqueado (precisa de %d.0 essência de boss)" % (i + 1)
		affix_labels[i].text = "Afixo cruzado: %s — %s" % [flavor_name, status]
```

- [ ] **Step 4: Adicionar as 2 linhas de afixo cruzado na cena via MCP `add_node`**

Sequência, dentro de `HUD/SkillTreePanel/VBox` (antes do `CloseButton`):
- `add_node` (`nodeType="Label"`, `nodeName="Affix1Label"`).
- `add_node` (`nodeType="Label"`, `nodeName="Affix2Label"`).

- [ ] **Step 5: Adicionar `@onready var affix_labels` em `scripts/skill_tree_panel.gd`**

```gdscript
@onready var affix_labels: Array[Label] = [$VBox/Affix1Label, $VBox/Affix2Label]
```

E chamar `_update_labels()` também sempre que o painel abrir (já faz isso em `open()`), garantindo que o estado de afixo apareça atualizado mesmo que tenha mudado enquanto o painel estava fechado (Review Focus).

- [ ] **Step 6: Verificar sintaxe e salvar cena**

`save_scene` (`scenePath="scenes/main.tscn"`). Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/skill_tree_panel.gd` — Expected: sem erro.

- [ ] **Step 7: Verificação manual — painel reflete a árvore certa e persistência do afixo entre aberturas (Review Focus)**

`run_project` com especialização Defensiva: abrir o painel, confirmar que os 4 nós mostram "Golem HP+", "Golem Cooldown-", "Golem Custo de Mana-", "Fúria do Guardião" (não os nomes da Destrutiva) e que os 2 afixos cruzados mostrados são "Estouro de Fogo" (Destrutiva) e "Dano Contínuo" (Maldição) — não "Lentidão" (Defensiva não dá afixo pra si mesma). Comprar um nó, fechar e reabrir o painel, confirmar que continua "comprado". Se possível (reaproveitando o forçar temporário do Task 5 Step 6), destravar 1 afixo, fechar o painel, reabrir e confirmar que ainda aparece "destravado" (estado vive no `BossTracker`, não no painel). `get_debug_output` sem erro. `stop_project`.

- [ ] **Step 8: Commit**

```bash
git add scripts/skill_tree_panel.gd scenes/main.tscn
git commit -m "feat: generaliza painel da arvore para as 3 especializacoes e afixos cruzados"
```

---

## Task 7: Atualizar roadmap e integração final

**Files:**
- Modify: `docs/roadmap.md`

- [ ] **Step 1: Atualizar a linha de estado atual em `docs/roadmap.md`**

Trocar "Estado atual do projeto: Fase 3 concluída... Próxima fase: Fase 4." para refletir Fase 4 concluída: as 3 árvores jogáveis como especialização (escolhida 1x no início, persistida em `user://save.json` — infraestrutura mínima que antecipa as Fases 5 e 8, citar o design doc), mini-boss/boss (tiers 4/5) disparados por contagem de mortes, e os 6 afixos cruzados destravados por essência de boss. Próxima fase: Fase 5.

- [ ] **Step 2: Verificação manual final — fluxo completo de ponta a ponta**

`run_project`. Com save limpo, escolher Maldição, jogar até matar 20+ inimigos (spawna mini-boss), confirmar essência de boss subindo, abrir o painel e comprar os 4 nós de Maldição, confirmar que o clique direito aplica o debuff e (depois de destravar os afixos) os efeitos cruzados de Destrutiva/Defensiva aparecem. `get_debug_output` sem erro em toda a sessão. `stop_project`.

- [ ] **Step 3: Commit**

```bash
git add docs/roadmap.md
git commit -m "docs: marca fase 4 como concluida no roadmap"
```
