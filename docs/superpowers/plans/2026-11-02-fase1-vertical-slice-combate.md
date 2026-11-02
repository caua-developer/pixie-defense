# Fase 1 — Vertical Slice de Combate Ativo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de criar/editar qualquer nó ou script Godot, re-consulte o card GodotPrompter pela skill `godot-prompter:*` correspondente (este plano já consultou `ability-system`, `ai-navigation`, `physics-system`, `godot-ui`, `input-handling` e `criacao-projeto-2d` — ver decisões abaixo). `CLAUDE.md` Regra 1 tem precedência sobre qualquer recomendação de abstração maior dessas skills.

**Goal:** Dentro de `res://scenes/main.tscn`, 1 inimigo tier branco avança por 1 corredor fixo até a torre; o jogador conjura 1 magia (mana + cooldown, mira de área livre por clique) para matá-lo antes que chegue; a base tem um pool de vida que desconta por inimigo que chega; perder (vida da base = 0) pausa o jogo e mostra "Fim de Fase".

**Architecture:** Composição direta de nós dentro de `main.tscn` (sem managers/EventBus — Regra 1 do `CLAUDE.md`). `Base` é um `Node` com sinal próprio (`base_defeated`); `Corredor1` é um `Path2D` cujo próprio script spawna inimigos via `Timer`; inimigos (`Area2D`, cena própria porque são instanciados repetidamente) avançam amostrando o `Curve2D` do corredor, sem `NavigationAgent2D` (confirmado over-engineering para 1 corredor fixo sem obstáculos — skill `ai-navigation`); o `Mago` lê clique do mouse via `Input Map` (ação `cast_spell`), valida mana/cooldown, e aplica dano em área via `PhysicsDirectSpaceState2D.intersect_shape` dentro de `_physics_process` (padrão confirmado pela skill `physics-system` — mais simples e instantâneo que spawnar `Area2D` e esperar sinal). HUD é `CanvasLayer > Control (Full Rect) > VBoxContainer` com `Label`s simples (sem tema/responsividade — fora de escopo). O nó raiz `Main` ganha um script só para conectar `Base.base_defeated` e atualizar os `Label`s do HUD a cada frame — não é um "manager" genérico, é o script da própria cena raiz.

**Tech Stack:** Godot 4.7 (GL Compatibility), GDScript com tipagem estática, edição de cena via MCP `godot` (`add_node`, `create_scene`, `save_scene`, `run_project`, `get_debug_output`, `stop_project`) com fallback para edição direta do `.tscn` via `Edit` nos casos que o MCP não cobre (anexar script, `Curve2D` como sub-resource) — confirmado pela skill `criacao-projeto-2d`.

**Spec:** `docs/roadmap.md` (seção "Fase 1 — Vertical slice de combate ativo"), `docs/project-context.md` (pilares 2, 3, 6, 8 parcial), `docs/balancing.md` (framework de economia — mana/cooldown não é coberto por `balancing.md`, por isso todos os valores numéricos de magia/inimigo/base nesta fase são hipótese explícita, a calibrar na Fase 10), `docs/design-system.md` (cor branca nativa = tier 0).

## Global Constraints

- Godot 4.7, renderer GL Compatibility; GDScript com tipagem estática em todo script novo.
- Cena principal fixa: `res://scenes/main.tscn`.
- Anti-over-engineering (`CLAUDE.md` Regra 1): nada de autoload/EventBus/manager/component genérico/state machine em nó/Resource de configuração nesta fase. `ability-system` e `ai-navigation` foram consultadas e **deliberadamente não seguidas** na parte que recomendaria `Ability` Resource genérico ou `NavigationAgent2D`/behavior tree — só existe 1 magia e 1 corredor sem obstáculo, então o padrão mínimo (variáveis diretas no script do Mago; amostragem manual de `Curve2D` no inimigo) é suficiente e é o que este plano usa.
- Escopo travado pelo `roadmap.md`: **fora desta fase** — multi-lane, árvores de habilidade, essência/dinheiro, geração procedural, VHS shader, mini-boss/boss, modos de dificuldade.
- Sem framework de teste automatizado nesta fase (decisão do usuário: Fase 1 valida "sensação", que é subjetiva/manual). Verificação via MCP (`run_project` + `get_debug_output`) e via `godot --headless --check-only --script <arquivo>` para sintaxe de cada script novo, usando o executável `C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`.
- Todo valor numérico de magia/inimigo/base abaixo é **hipótese explícita** (não coberta por `balancing.md`, que só define economia de essência/dinheiro/dificuldade) — marcada como tal em cada task, a calibrar na Fase 10.
- HUD usa `Control` + `Container` (nunca posicionamento manual), mesmo sendo minimalista — confirmado pela skill `godot-ui`.
- Clique de conjuração usa uma ação do Input Map (`cast_spell`), não checagem crua de `InputEventMouseButton` — confirmado pela skill `input-handling`; sem rebind nesta fase.
- Inimigos ficam na layer de física nomeada "inimigos" (layer 2); a query de dano em área usa `collision_mask` para essa layer e `collide_with_areas = true` / `collide_with_bodies = false` (inimigo é `Area2D`) — confirmado pela skill `physics-system`.

## Review Focus

- **Clique em área vazia (sem inimigo por perto):** deve consumir mana e iniciar cooldown mesmo sem acertar nada — é a mecânica pretendida (decisão errada de onde/quando é o custo real), não um bug a esconder. Verificado na Task 5.
- **Clique repetido durante o cooldown:** o segundo clique não pode gastar mana nem reiniciar o cooldown. Verificado na Task 5.
- **Mana insuficiente com cooldown liberado:** cast deve falhar sem descontar mana parcial nem iniciar cooldown. Verificado na Task 5.
- **Múltiplos inimigos dentro do mesmo raio de efeito:** todos devem tomar dano na mesma conjuração (valida o pilar de mira de área livre atingindo mais de uma ameaça). Verificado na Task 6 (precisa de 2+ inimigos vivos simultaneamente, então o teste força `spawn_interval` curto o bastante para isso ocorrer uma vez).
- **Vida da base chega a 0 com inimigo(s) ainda em trânsito:** o jogo deve pausar imediatamente (via `get_tree().paused = true`) sem continuar descontando vida negativa nem deixar o `Timer` de spawn ou o inimigo em movimento continuar processando depois — como `get_tree().paused` afeta todos os nós em modo `PROCESS_MODE_PAUSABLE` (default), isso é automático; verificado na Task 8.

---

## Task 1: Configuração de projeto (Input Map + layer de física)

**Files:**
- Modify: `project.godot` (seções `[input]` e `[layer_names]`)

**Interfaces:**
- Produces: ação de input `cast_spell` (clique esquerdo do mouse) que a Task 5 usa em `_unhandled_input`; layer de física 2D nomeada "inimigos" (bit 2) que a Task 3 (Enemy) e a Task 5 (query de dano) usam via `collision_layer`/`collision_mask`.

- [ ] **Step 1: Adicionar a ação `cast_spell` na seção `[input]`**

```
[input]

cast_spell={
"deadzone": 0.2,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":false,"double_click":false,"script":null)
]
}
```

- [ ] **Step 2: Nomear a layer de física 2D 2 como "inimigos" na seção `[layer_names]`**

```
[layer_names]

2d_physics/layer_2="inimigos"
```

- [ ] **Step 3: Verificar o arquivo**

Ler `project.godot` e confirmar as duas seções novas.

- [ ] **Step 4: Commit**

```bash
git add project.godot
git commit -m "config: adiciona acao cast_spell e layer de fisica inimigos"
```

---

## Task 2: Nó `Base` (pool de vida)

**Files:**
- Create: `scripts/base.gd`
- Modify: `scenes/main.tscn` (via MCP `add_node` + `Edit` para o script)

**Interfaces:**
- Produces: nó `root/Base` (grupo `"base"`), propriedade `current_life: float`, constante `MAX_LIFE: float = 100.0`, método `take_damage(amount: float) -> void`, sinal `base_defeated`. A Task 3 (Enemy) usa `get_tree().get_first_node_in_group("base")` + `take_damage`. A Task 7 (HUD) lê `current_life`/`MAX_LIFE`. A Task 8 (Main) conecta `base_defeated`.

- [ ] **Step 1: Criar `scripts/base.gd`**

```gdscript
extends Node

signal base_defeated

const MAX_LIFE: float = 100.0  # hipótese, calibrar na Fase 10 (balancing.md não cobre vida da base em número)

var current_life: float = MAX_LIFE

func _ready() -> void:
	add_to_group("base")

func take_damage(amount: float) -> void:
	if current_life <= 0.0:
		return
	current_life = max(0.0, current_life - amount)
	if current_life <= 0.0:
		base_defeated.emit()
```

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/base.gd`
Expected: sem erro de sintaxe (saída vazia ou sem "Error").

- [ ] **Step 3: Adicionar o nó `Base` (`Node`) como filho de `root` via MCP `add_node`**

`nodeType="Node"`, `nodeName="Base"`, `parentNodePath="root"`.

- [ ] **Step 4: Anexar o script via `Edit` em `scenes/main.tscn`**

Ler o arquivo atual, adicionar `[ext_resource type="Script" path="res://scripts/base.gd" id="base_script"]` perto do topo (após o cabeçalho `[gd_scene ...]`, incrementando `load_steps` em 1) e `script = ExtResource("base_script")` no bloco `[node name="Base" type="Node" parent="."]`.

- [ ] **Step 5: Salvar e verificar**

`save_scene` (`scenePath="scenes/main.tscn"`), depois ler o arquivo e confirmar o `ext_resource` e o `script =` no nó `Base`.

- [ ] **Step 6: Commit**

```bash
git add scripts/base.gd scenes/main.tscn
git commit -m "feat: adiciona pool de vida da base"
```

---

## Task 3: Cena `Enemy` (inimigo tier branco)

**Files:**
- Create: `scenes/enemy.tscn`
- Create: `scripts/enemy.gd`

**Interfaces:**
- Consumes: grupo `"base"` + `Base.take_damage(amount: float)` (Task 2).
- Produces: cena `res://scenes/enemy.tscn`, raiz `Area2D` no grupo `"inimigos"`, `collision_layer` = layer 2 ("inimigos"), `collision_mask = 0`. Método público `set_path_curve(curve: Curve2D) -> void` e `take_damage(amount: float) -> void` que a Task 5 (query de dano) e a Task 6 (spawner) usam.

- [ ] **Step 1: Criar `scripts/enemy.gd`**

```gdscript
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
```

Minha decisão: amostragem manual de `Curve2D` (`sample_baked`) em vez de `PathFollow2D` — mantém a raiz da cena como `Area2D` puro (sem nó `PathFollow2D` intermediário), o que simplifica a detecção por `intersect_shape` na Task 5. Confirmado pela skill `ai-navigation` que, para 1 corredor fixo sem obstáculo, isso é suficiente e `NavigationAgent2D`/steering seria over-engineering nesta fase.

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/enemy.gd`
Expected: sem erro.

- [ ] **Step 3: Criar a cena via MCP**

`create_scene` (`scenePath="scenes/enemy.tscn"`, `rootNodeType="Area2D"`).

- [ ] **Step 4: Adicionar `CollisionShape2D` e o visual placeholder via MCP `add_node`**

`add_node` (`parentNodePath="root"`, `nodeType="CollisionShape2D"`, `nodeName="CollisionShape2D"`, `properties={"shape": {"radius": 12.0}}` se o MCP aceitar shape inline; caso contrário, criar via `Edit` um `sub_resource` `CircleShape2D` com `radius = 12.0` e referenciá-lo no nó).

`add_node` (`parentNodePath="root"`, `nodeType="Polygon2D"`, `nodeName="Visual"`, `properties={"polygon": [[-12,-12],[12,-12],[12,12],[-12,12]], "color": [1,1,1,1]}`) — branco puro, cor nativa do tier 0 (`design-system.md`).

- [ ] **Step 5: Configurar `collision_layer`/`collision_mask` e anexar o script via `Edit`**

No bloco `[node name="root" type="Area2D"]` (ou nome que o MCP tenha dado à raiz): adicionar `collision_layer = 2`, `collision_mask = 0`, `[ext_resource type="Script" path="res://scripts/enemy.gd" id="enemy_script"]` e `script = ExtResource("enemy_script")`.

- [ ] **Step 6: Salvar e verificar**

`save_scene` (`scenePath="scenes/enemy.tscn"`). Ler o arquivo e confirmar: `CollisionShape2D` com raio 12, `Polygon2D` branco 24×24, `collision_layer = 2`, `collision_mask = 0`, script anexado.

- [ ] **Step 7: Commit**

```bash
git add scenes/enemy.tscn scripts/enemy.gd
git commit -m "feat: adiciona cena do inimigo tier branco"
```

---

## Task 4: Cena `SpellEffect` (feedback visual da área de efeito)

**Files:**
- Create: `scenes/spell_effect.tscn`
- Create: `scripts/spell_effect.gd`

**Interfaces:**
- Produces: cena `res://scenes/spell_effect.tscn`, raiz `Node2D` com propriedade pública `radius: float` que a Task 5 define antes de `add_child`.

- [ ] **Step 1: Criar `scripts/spell_effect.gd`**

```gdscript
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
```

Minha decisão: cor lavanda translúcida (mesma família do placeholder do Mago na Fase 0) e duração fixa de 0.15s — puramente feedback de onde a magia acertou, sem papel de comunicar dificuldade (isso é exclusivo da cor de tier, `design-system.md`).

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/spell_effect.gd`
Expected: sem erro.

- [ ] **Step 3: Criar a cena e o `Timer` filho via MCP**

`create_scene` (`scenePath="scenes/spell_effect.tscn"`, `rootNodeType="Node2D"`).
`add_node` (`parentNodePath="root"`, `nodeType="Timer"`, `nodeName="Timer"`).

- [ ] **Step 4: Anexar o script via `Edit`**

Adicionar `[ext_resource type="Script" path="res://scripts/spell_effect.gd" id="effect_script"]` e `script = ExtResource("effect_script")` no nó raiz.

- [ ] **Step 5: Salvar e verificar**

`save_scene` (`scenePath="scenes/spell_effect.tscn"`). Ler o arquivo e confirmar `Timer` filho e script anexado na raiz.

- [ ] **Step 6: Commit**

```bash
git add scenes/spell_effect.tscn scripts/spell_effect.gd
git commit -m "feat: adiciona efeito visual da magia de area"
```

---

## Task 5: Script do Mago (mana, cooldown, conjuração em área)

**Files:**
- Create: `scripts/mago.gd`
- Modify: `scenes/main.tscn` (anexar script ao nó `Mago` existente via `Edit`)

**Interfaces:**
- Consumes: ação de input `cast_spell` (Task 1); grupo `"inimigos"` + `Enemy.take_damage(amount: float)` (Task 3); cena `res://scenes/spell_effect.tscn` com propriedade `radius` (Task 4).
- Produces: propriedades `mana: float`, constante `MAX_MANA: float = 100.0` que a Task 7 (HUD) lê.

- [ ] **Step 1: Criar `scripts/mago.gd`**

```gdscript
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
```

Minha decisão (Regra 1 / skill `ability-system`): nada de `Ability` Resource nem `AbilityComponent` genérico — só existe 1 magia nesta fase, então mana/custo/cooldown ficam como variáveis diretas no script do Mago. A query de dano usa `PhysicsDirectSpaceState2D.intersect_shape` dentro de `_physics_process` (único contexto seguro para isso, confirmado pela skill `physics-system`) em vez de instanciar um `Area2D` temporário e esperar um sinal — mais simples e instantâneo para um efeito sem duração.

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/mago.gd`
Expected: sem erro.

- [ ] **Step 3: Anexar o script ao nó `Mago` existente via `Edit`**

Ler `scenes/main.tscn`, adicionar `[ext_resource type="Script" path="res://scripts/mago.gd" id="mago_script"]` e `[ext_resource type="PackedScene" path="res://scenes/spell_effect.tscn" id="spell_effect_scene"]`, e no bloco `[node name="Mago" type="Node2D" parent="."]` adicionar `script = ExtResource("mago_script")` e `spell_effect_scene = ExtResource("spell_effect_scene")`.

- [ ] **Step 4: Salvar e verificar**

`save_scene` (`scenePath="scenes/main.tscn"`). Ler o arquivo e confirmar os dois `ext_resource` e as duas propriedades no nó `Mago`.

- [ ] **Step 5: Verificação manual via MCP — clique em área vazia não acerta nada mas consome recurso**

`run_project`, clicar numa área sem inimigo, `get_debug_output` (sem erro), parar (`stop_project`). Confirmar visualmente: `cooldown_remaining`/`mana` mudaram (via print de debug temporário ou observação do HUD da Task 7, que ainda não existe nesta task — se a Task 7 ainda não foi feita, adicionar um `print(mana, cooldown_remaining)` temporário em `_try_cast` só para esta verificação manual, e removê-lo antes do commit).

- [ ] **Step 6: Verificação manual — clique repetido durante cooldown não gasta mana de novo**

Clicar duas vezes rapidamente; confirmar (via o mesmo print temporário) que `mana` só diminuiu uma vez.

- [ ] **Step 7: Verificação manual — mana insuficiente não gasta nada**

Forçar `mana = 10.0` temporariamente no `_ready` só para o teste, clicar, confirmar que `mana` não mudou e `cooldown_remaining` continua 0. Reverter a alteração temporária antes do commit.

- [ ] **Step 8: Commit**

```bash
git add scripts/mago.gd scenes/main.tscn
git commit -m "feat: adiciona mana, cooldown e conjuracao em area do mago"
```

---

## Task 6: Nó `Corredor1` (corredor fixo + spawn de inimigos)

**Files:**
- Create: `scripts/corredor.gd`
- Modify: `scenes/main.tscn` (via MCP `add_node` + `Edit` para `Curve2D`, script e `Timer`)

**Interfaces:**
- Consumes: cena `res://scenes/enemy.tscn` (Task 3), método `Enemy.set_path_curve(curve: Curve2D)`.
- Produces: nó `root/Corredor1` (`Path2D`) com `position = Vector2(0, 0)` e `Curve2D` de 2 pontos: início `(600, 0)`, fim `(0, 0)` (mesmo ponto do `Mago`, coincidindo com o centro da torre).

- [ ] **Step 1: Criar `scripts/corredor.gd`**

```gdscript
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
```

Minha decisão: o spawner vive no próprio `Path2D` do corredor (não um "spawner manager" separado) — cada corredor é autossuficiente, o que já antecipa a Fase 2 (múltiplos corredores, cada um com seu próprio `Corredor*.gd`) sem introduzir nenhuma abstração nova agora (é só repetir este mesmo nó, não criar um sistema).

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/corredor.gd`
Expected: sem erro.

- [ ] **Step 3: Adicionar o nó `Corredor1` (`Path2D`) e `SpawnTimer` (`Timer`) via MCP `add_node`**

`add_node` (`parentNodePath="root"`, `nodeType="Path2D"`, `nodeName="Corredor1"`, `properties={"position": {"x": 0, "y": 0}}`).
`add_node` (`parentNodePath="root/Corredor1"`, `nodeType="Timer"`, `nodeName="SpawnTimer"`).

- [ ] **Step 4: Definir a `Curve2D` do `Corredor1` via `Edit`**

Ler `scenes/main.tscn`. Adicionar um `sub_resource` `Curve2D`:

```
[sub_resource type="Curve2D" id="corredor1_curve"]
_data = {
"points": PackedVector2Array(0, 0, 600, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}
```

(2 pontos sem tangente de controle: cada ponto são 3 `Vector2` — `in`, `point`, `out`, nessa ordem — então 2 pontos = 6 `Vector2` = 12 números. Sequência acima: `in1=(0,0)`, `point1=(600,0)` [início], `out1=(0,0)`, `in2=(0,0)`, `point2=(0,0)` [fim, coincide com o `Mago`], `out2=(0,0)`.)

No bloco `[node name="Corredor1" type="Path2D" parent="."]`, adicionar `curve = SubResource("corredor1_curve")`.

- [ ] **Step 5: Anexar o script e a referência à cena do inimigo via `Edit`**

Adicionar `[ext_resource type="Script" path="res://scripts/corredor.gd" id="corredor_script"]` e `[ext_resource type="PackedScene" path="res://scenes/enemy.tscn" id="enemy_scene"]`. No bloco do `Corredor1`, adicionar `script = ExtResource("corredor_script")` e `enemy_scene = ExtResource("enemy_scene")`.

- [ ] **Step 6: Salvar e verificar**

`save_scene` (`scenePath="scenes/main.tscn"`). Ler o arquivo e confirmar: `Corredor1` com `curve` apontando para o sub-resource, `script` e `enemy_scene` atribuídos, `SpawnTimer` filho.

- [ ] **Step 7: Verificação manual — inimigo nasce, anda até o centro e some ao chegar**

`run_project`, aguardar >2s, observar (visualmente, pelo quadrado branco) o inimigo se mover de `(600,0)` até `(0,0)` e desaparecer ao chegar; `get_debug_output` sem erro; `stop_project`.

- [ ] **Step 8: Verificação manual — múltiplos inimigos no mesmo raio de efeito tomam dano juntos**

Com `SPAWN_INTERVAL` temporariamente reduzido para `0.3` só para este teste (reverter depois), `run_project`, deixar 2+ inimigos ficarem próximos um do outro dentro do alcance de 80px, clicar entre eles, confirmar (visualmente, pelo desaparecimento) que ambos morrem na mesma conjuração. Reverter `SPAWN_INTERVAL` para `2.0` antes do commit.

- [ ] **Step 9: Commit**

```bash
git add scripts/corredor.gd scenes/main.tscn
git commit -m "feat: adiciona corredor fixo com spawn de inimigos"
```

---

## Task 7: HUD mínimo (mana, vida da base, texto de fim de fase)

**Files:**
- Modify: `scenes/main.tscn` (via MCP `add_node`)

**Interfaces:**
- Produces: nós `root/HUD/Root/VBox/ManaLabel`, `.../BaseLifeLabel`, `.../GameOverLabel` (`Label`s) que a Task 8 (script `Main`) atualiza e controla.

- [ ] **Step 1: Adicionar a hierarquia de UI via MCP `add_node`**

`add_node` (`parentNodePath="root"`, `nodeType="CanvasLayer"`, `nodeName="HUD"`).
`add_node` (`parentNodePath="root/HUD"`, `nodeType="Control"`, `nodeName="Root"`, `properties={"anchor_right": 1, "anchor_bottom": 1}`).
`add_node` (`parentNodePath="root/HUD/Root"`, `nodeType="VBoxContainer"`, `nodeName="VBox"`, `properties={"offset_left": 16, "offset_top": 16}`).
`add_node` (`parentNodePath="root/HUD/Root/VBox"`, `nodeType="Label"`, `nodeName="ManaLabel"`, `properties={"text": "Mana: 100/100"}`).
`add_node` (`parentNodePath="root/HUD/Root/VBox"`, `nodeType="Label"`, `nodeName="BaseLifeLabel"`, `properties={"text": "Vida da Base: 100/100"}`).
`add_node` (`parentNodePath="root/HUD/Root/VBox"`, `nodeType="Label"`, `nodeName="GameOverLabel"`, `properties={"text": "FIM DE FASE", "visible": false}`).

Minha decisão: `Control "Root"` com `anchor_right=1`/`anchor_bottom=1` (preset Full Rect) contendo um único `VBoxContainer` posicionado por offset no canto superior esquerdo — é o mínimo de `Container` necessário pra não cair em posicionamento manual dos `Label`s (confirmado pela skill `godot-ui`), sem tema/responsividade (fora de escopo desta fase).

- [ ] **Step 2: Salvar e verificar**

`save_scene` (`scenePath="scenes/main.tscn"`). Ler o arquivo e confirmar a árvore `HUD > Root > VBox > (ManaLabel, BaseLifeLabel, GameOverLabel)` com as propriedades esperadas.

- [ ] **Step 3: Commit**

```bash
git add scenes/main.tscn
git commit -m "feat: adiciona hud minimo de mana, vida da base e fim de fase"
```

---

## Task 8: Script `Main` (wiring de fim de fase) + verificação end-to-end

**Files:**
- Create: `scripts/main.gd`
- Modify: `scenes/main.tscn` (anexar script ao nó raiz `Main` via `Edit`)
- Modify: `docs/roadmap.md`

**Interfaces:**
- Consumes: `Base.base_defeated` (Task 2), `Mago.mana`/`Mago.MAX_MANA` (Task 5), `Base.current_life`/`Base.MAX_LIFE` (Task 2), `root/HUD/Root/VBox/{ManaLabel,BaseLifeLabel,GameOverLabel}` (Task 7).

- [ ] **Step 1: Criar `scripts/main.gd`**

```gdscript
extends Node2D

@onready var base: Node = $Base
@onready var mago: Node2D = $Mago
@onready var mana_label: Label = $HUD/Root/VBox/ManaLabel
@onready var base_life_label: Label = $HUD/Root/VBox/BaseLifeLabel
@onready var game_over_label: Label = $HUD/Root/VBox/GameOverLabel

func _ready() -> void:
	game_over_label.visible = false
	base.base_defeated.connect(_on_base_defeated)

func _process(_delta: float) -> void:
	mana_label.text = "Mana: %d/%d" % [int(mago.mana), int(mago.MAX_MANA)]
	base_life_label.text = "Vida da Base: %d/%d" % [int(base.current_life), int(base.MAX_LIFE)]

func _on_base_defeated() -> void:
	game_over_label.visible = true
	get_tree().paused = true
```

Minha decisão: pausar via `get_tree().paused = true` em vez de parar manualmente cada `Timer`/inimigo — todos os nós relevantes ficam em `PROCESS_MODE_PAUSABLE` (padrão), então a pausa já congela spawn, movimento e cooldown de uma vez, sem precisar de uma rotina de "fim de fase" espalhada por vários scripts.

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/main.gd`
Expected: sem erro.

- [ ] **Step 3: Anexar o script ao nó `Main` via `Edit`**

Ler `scenes/main.tscn`, adicionar `[ext_resource type="Script" path="res://scripts/main.gd" id="main_script"]` e `script = ExtResource("main_script")` no bloco `[node name="Main" type="Node2D"]` (raiz).

- [ ] **Step 4: Salvar**

`save_scene` (`scenePath="scenes/main.tscn"`).

- [ ] **Step 5: Verificação manual — vida da base chega a 0 pausa o jogo**

`run_project`. Deixar pelo menos 10 inimigos chegarem sem matar nenhum (10 × `CONTACT_DAMAGE` 10.0 = `MAX_LIFE` 100.0) — ou, só para agilizar este teste manual, reduzir temporariamente `Base.MAX_LIFE` para `10.0` (reverter depois). Confirmar: `GameOverLabel` fica visível, o jogo pausa (inimigos/spawn param de se mover), `get_debug_output` sem erro. `stop_project`. Reverter qualquer alteração temporária de `MAX_LIFE` antes do commit.

- [ ] **Step 6: Verificação manual end-to-end completa**

`run_project`: confirmar que o HUD mostra mana/vida da base atualizando, que o inimigo nasce e anda pelo corredor, que o clique com mana/cooldown ok mata o inimigo dentro do raio (mostrando o efeito visual lavanda), e que nenhum erro aparece em `get_debug_output` durante todo o percurso. `stop_project`. Pedir confirmação visual do usuário.

- [ ] **Step 7: Atualizar `docs/roadmap.md`**

Trocar a linha "Estado atual do projeto: Fase 0 concluída... Próxima fase: Fase 1." para refletir Fase 1 concluída e Fase 2 como próxima, citando este plano.

- [ ] **Step 8: Commit**

```bash
git add scripts/main.gd scenes/main.tscn docs/roadmap.md
git commit -m "feat: conecta fim de fase e conclui fase 1"
```
