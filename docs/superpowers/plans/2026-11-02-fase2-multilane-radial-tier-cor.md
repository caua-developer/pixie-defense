# Fase 2 — Multi-lane Radial + Tier de Cor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de criar/editar qualquer nó ou script Godot, re-consulte o card GodotPrompter pela skill `godot-prompter:*` correspondente (este plano já consultou `shader-basics`, `math-essentials` e `camera-system` — ver decisões abaixo). `CLAUDE.md` Regra 1 tem precedência sobre qualquer recomendação de abstração maior dessas skills.

**Goal:** Expandir `res://scenes/main.tscn` de 1 corredor fixo (Fase 1) para 3 corredores fixos dispostos radialmente ao redor da torre, todos visíveis simultaneamente sem scroll de câmera; cada inimigo nasce com um tier de cor (branco/verde/azul/vermelho) sorteado de uma proporção fixa, aplicado via shader de tint, com hp/velocidade/dano escalando por tier; a magia de área livre continua acertando inimigos de corredores diferentes numa única conjuração.

**Architecture:** Cada corredor continua um `Path2D` autossuficiente com seu próprio script e `SpawnTimer` (mesmo padrão da Fase 1, agora reaproveitado 3x — nenhum spawner/manager central). A única mudança estrutural em `corredor.gd` é que ele passa a construir seu próprio `Curve2D` em runtime a partir de uma posição de início exportada (`start_position`), em vez de depender de um sub-resource `Curve2D` editado à mão — isso evita a duplicação que existiria com 3 sub-resources manuais quase idênticos (agora que existe o "terceiro caso real" que a Regra 1 do `CLAUDE.md` usa como critério pra parar de aceitar duplicação). O tier de cada inimigo é sorteado no próprio `corredor.gd` (tabela de pesos fixa, sem progressão por dia — fora de escopo desta fase) e aplicado ao inimigo recém-instanciado via um novo método público `set_tier(tier: int)` em `enemy.gd`, que ajusta hp/velocidade/dano por multiplicadores fixos e seta o parâmetro de um `ShaderMaterial` (canvas_item, tint por multiplicação) já atribuído ao `Polygon2D` placeholder do inimigo. Nenhum manager, EventBus, Resource genérico de tier ou `NavigationAgent2D` é introduzido — tudo fica em consts/arrays diretos nos dois scripts já existentes, e a câmera ganha apenas um ajuste de `zoom` para enquadrar os 3 corredores.

**Tech Stack:** Godot 4.7 (GL Compatibility), GDScript com tipagem estática, edição de cena via MCP `godot` (`add_node`, `save_scene`, `run_project`, `get_debug_output`, `stop_project`) com fallback para `Edit` direto no `.tscn`/`.gdshader` nos casos que o MCP não cobre (shader, `ShaderMaterial`, ajuste de propriedades já existentes).

**Spec:** `docs/roadmap.md` (seção "Fase 2 — Multi-lane radial + tier de cor"), `docs/project-context.md` (pilar 3 — multi-lane radial), `docs/design-system.md` (paleta de tier fixa, shader de tint, composição radial), `docs/balancing.md` (nº de lanes por marco de progressão fica **fora** desta fase — ver Global Constraints).

## Global Constraints

- Godot 4.7, renderer GL Compatibility; GDScript com tipagem estática em todo script novo/modificado.
- Cena principal fixa: `res://scenes/main.tscn`.
- **N = 3 corredores fixos nesta fase** (decisão do usuário) — a ideia de "1 a 5 corredores por marco de progressão do save" (`balancing.md`, pendência "Nº de lanes por marco de progressão") **não** é implementada agora; fica registrada como escopo de fase futura (Fase 6/7, que já tratam de progressão entre dias). Esta fase não escala corredores dinamicamente.
- Anti-over-engineering (`CLAUDE.md` Regra 1): sem autoload/EventBus/manager/Resource genérico de tier nesta fase. O shader de tint é a única peça "não-trivial" desta fase e está documentado como exceção porque `roadmap.md` (Fase 2) e `design-system.md` exigem explicitamente "tier de cor via shader de tint sobre o sprite branco".
- Proporção de tier e multiplicadores de hp/velocidade/dano por tier são **hipóteses explícitas** (não calibradas por playtesting) — `balancing.md` só define proporção por dia pra fases futuras (Fase 7), não um valor fixo pra Fase 2; os valores abaixo são a decisão do implementador pra esta fase, a recalibrar na Fase 10.
- Cor exata de cada tier (verde/azul/vermelho) também é hipótese visual — `design-system.md` explicitamente deixa a matiz exata para calibração em protótipo.
- Sem framework de teste automatizado nesta fase (mesma decisão herdada da Fase 1: a validação é perceptual — "dá pra decidir entre 3 ameaças simultâneas?", "o tier é legível?" — não unit-testável). Verificação via MCP (`run_project` + `get_debug_output`) e `godot --headless --check-only --script <arquivo>` para sintaxe de cada script, usando `C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`.
- Escopo travado pelo `roadmap.md`: **fora desta fase** — geração procedural dos corredores (continuam fixos), economia (essência/dinheiro), árvores de habilidade, VHS shader, mini-boss/boss, modos de dificuldade.

## Review Focus

- **Mira de área perto do centro ainda acerta inimigos de corredores diferentes numa única conjuração:** com 3 lanes convergindo no mesmo ponto (0,0), o pilar "mira de área livre pode atingir mais de um corredor" precisa continuar válido — verificado na Task 4 Step 4.
- **Distribuição de tier ponderada nunca falha silenciosamente num extremo:** o loop de seleção cumulativa não pode deixar de cobrir o último tier (vermelho, peso baixo) nem travar com `roll == total`. Verificado na Task 4 Step 5.
- **Todos os 3 corredores (incluindo os pontos de spawn nas extremidades) ficam visíveis em 1280×720 sem mover a câmera** — é um requisito explícito de `design-system.md` ("topologia radial"), não só estética. Verificado na Task 4 Step 3.
- **Vida da base continua descontando e pausando corretamente com 3 spawners simultâneos** (mais chance de 2+ inimigos chegarem no mesmo frame do que na Fase 1 com 1 corredor só) — regressão da Fase 1 sob nova condição de concorrência. Verificado na Task 4 Step 6.
- **Inimigo tier 0 (branco) continua idêntico à Fase 1 após o refactor de `enemy.gd`** (cor nativa, 1 acerto de magia mata, mesma velocidade) — regressão de uma mecânica já validada. Verificado na Task 1 Step 7 e na Task 4 Step 7.

---

## Task 1: Sistema de tier do inimigo (shader de tint + stats por tier)

**Files:**
- Create: `shaders/enemy_tint.gdshader`
- Modify: `scripts/enemy.gd`
- Modify: `scenes/enemy.tscn`

**Interfaces:**
- Produces: método público `Enemy.set_tier(tier: int) -> void` (índices 0=branco, 1=verde, 2=azul, 3=vermelho) que a Task 2 (`corredor.gd`) chama antes de `set_path_curve`. Mantém `set_path_curve(curve: Curve2D)` e `take_damage(amount: float)` inalterados na assinatura (consumidos por `corredor.gd` e `mago.gd` da Fase 1).

- [ ] **Step 1: Criar `shaders/enemy_tint.gdshader`**

```glsl
shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = tex_color * tint_color;
}
```

Minha decisão (skill `shader-basics`): shader `canvas_item` simples de multiplicação de cor, sem lógica adicional — é exatamente o que `design-system.md` pede ("tint sobre o sprite branco, nunca editando o asset-fonte") e já funciona tanto sobre o `Polygon2D` placeholder atual (que amostra branco por padrão) quanto sobre um sprite de textura real quando a Fase 9 trocar os placeholders pelos assets finais.

- [ ] **Step 2: Reescrever `scripts/enemy.gd`**

```gdscript
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
```

Minha decisão: `hp`/`speed`/`contact_damage` passam de `const`/fixos pra `var` ajustáveis por `set_tier`, mantendo `MAX_HP`/`SPEED`/`CONTACT_DAMAGE` como base do tier 0 (branco) — zero mudança de comportamento se `set_tier` nunca for chamado (default dos `var` já é o valor base), o que preserva a Review Focus de regressão do tier 0.

- [ ] **Step 3: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/enemy.gd`
Expected: sem erro.

- [ ] **Step 4: Adicionar `ShaderMaterial` ao nó `Visual` em `scenes/enemy.tscn` via `Edit`**

Ler `scenes/enemy.tscn`. Adicionar, após o `[ext_resource type="Script" ...]` existente:

```
[ext_resource type="Shader" path="res://shaders/enemy_tint.gdshader" id="tint_shader"]

[sub_resource type="ShaderMaterial" id="enemy_tint_material"]
shader = ExtResource("tint_shader")
shader_parameter/tint_color = Color(1, 1, 1, 1)
```

E no bloco `[node name="Visual" type="Polygon2D" parent="."]`, adicionar `material = SubResource("enemy_tint_material")`. Incrementar `load_steps` no cabeçalho `[gd_scene ...]` em 2 (1 ext_resource + 1 sub_resource novos).

- [ ] **Step 5: Salvar e verificar**

`save_scene` (`scenePath="scenes/enemy.tscn"`). Ler o arquivo e confirmar o `ext_resource` do shader, o `sub_resource` `ShaderMaterial` e `material = SubResource(...)` no nó `Visual`.

- [ ] **Step 6: Verificação manual temporária — tint e multiplicadores funcionam**

Adicionar temporariamente `set_tier(3)` ao final de `_ready()` em `scripts/enemy.gd` (força tier vermelho em todo inimigo nascido, só para este teste). `run_project`, aguardar um inimigo nascer (via `Corredor1` já existente da Fase 1), confirmar visualmente que ele aparece vermelho e anda visivelmente mais rápido que antes; `get_debug_output` sem erro; `stop_project`.

- [ ] **Step 7: Reverter a chamada temporária e confirmar regressão do tier 0**

Remover a linha `set_tier(3)` adicionada no Step 6. `run_project`, confirmar visualmente que o inimigo volta a nascer branco (cor nativa); `stop_project`.

- [ ] **Step 8: Commit**

```bash
git add shaders/enemy_tint.gdshader scripts/enemy.gd scenes/enemy.tscn
git commit -m "feat: adiciona sistema de tier (shader de tint + stats) ao inimigo"
```

---

## Task 2: `corredor.gd` paramétrico + seleção de tier ponderada

**Files:**
- Modify: `scripts/corredor.gd`

**Interfaces:**
- Consumes: `Enemy.set_tier(tier: int)` (Task 1).
- Produces: `@export var start_position: Vector2` (default `Vector2(600, 0)`, idêntico ao ponto de início hardcoded da Fase 1) que a Task 3 usa para configurar `Corredor1`/`Corredor2`/`Corredor3` em `main.tscn`.

- [ ] **Step 1: Reescrever `scripts/corredor.gd`**

```gdscript
extends Path2D

const SPAWN_INTERVAL: float = 2.0  # segundos, hipótese — calibrar na Fase 10

# Proporção fixa de tier nesta fase (sem progressão por dia — balancing.md trata isso só a partir da Fase 7)
# Índices: 0 branco, 1 verde, 2 azul, 3 vermelho
const TIER_WEIGHTS: Array[float] = [60.0, 25.0, 12.0, 3.0]  # hipótese — calibrar na Fase 10

@export var enemy_scene: PackedScene
@export var start_position: Vector2 = Vector2(600, 0)

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	var path_curve := Curve2D.new()
	path_curve.add_point(start_position)
	path_curve.add_point(Vector2.ZERO)
	curve = path_curve
	spawn_timer.wait_time = SPAWN_INTERVAL
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	var enemy: Area2D = enemy_scene.instantiate()
	enemy.position = curve.sample_baked(0.0, true)
	enemy.set_tier(_pick_tier())
	enemy.set_path_curve(curve)
	get_parent().add_child(enemy)

func _pick_tier() -> int:
	var total: float = 0.0
	for weight in TIER_WEIGHTS:
		total += weight
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in TIER_WEIGHTS.size():
		cumulative += TIER_WEIGHTS[i]
		if roll < cumulative:
			return i
	return TIER_WEIGHTS.size() - 1
```

Minha decisão (skill `math-essentials`, seção de seleção aleatória ponderada): soma cumulativa simples sobre um array fixo de 4 pesos — método mais direto pra 4 opções, sem precisar de `RandomNumberGenerator` seedado (nenhuma necessidade de reprodutibilidade nesta fase, diferente da geração procedural da Fase 6). O `return` final fora do loop cobre o caso de arredondamento de float em `roll == total` (Review Focus).

Minha decisão (Regra 1 / Curve2D em runtime): o corredor monta sua própria `Curve2D` de 2 pontos (início exportado → fim em `Vector2.ZERO`, sempre coincidindo com a posição do `Mago`) em vez de depender de um sub-resource `Curve2D` editado à mão na cena — com 3 corredores agora (o "terceiro caso real" da Regra 1), repetir esse sub-resource manualmente 3x seria a duplicação que a regra pede pra evitar; isso não introduz abstração nova, só move o mesmo dado (ponto de início) de um sub-resource pra uma propriedade exportada do próprio script que já existe.

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/corredor.gd`
Expected: sem erro.

- [ ] **Step 3: Verificação manual — `Corredor1` (ainda sozinho nesta task) continua funcionando e varia de tier**

`run_project`. `Corredor1` em `main.tscn` ainda não tem `start_position` setado explicitamente, então usa o default `Vector2(600, 0)` — comportamento idêntico à Fase 1. Aguardar ~20s (várias ondas de `SPAWN_INTERVAL` 2.0s) e confirmar visualmente que a maioria dos inimigos nasce branca mas cores diferentes aparecem ocasionalmente; `get_debug_output` sem erro; `stop_project`.

- [ ] **Step 4: Commit**

```bash
git add scripts/corredor.gd
git commit -m "feat: corredor monta curva por start_position e sorteia tier por peso"
```

---

## Task 3: 3 corredores radiais em `main.tscn`

**Files:**
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: `Corredor.start_position` export, `corredor_script`/`enemy_scene` ext_resources já existentes na cena (Fase 1 + Task 2).

- [ ] **Step 1: Remover o sub-resource de curva estático e atualizar o nó `Corredor1` via `Edit`**

Ler `scenes/main.tscn`. Remover o bloco `[sub_resource type="Curve2D" id="corredor1_curve"]` (não é mais usado — `corredor.gd` monta a curva em runtime). No bloco `[node name="Corredor1" type="Path2D" parent="."]`, remover a linha `curve = SubResource("corredor1_curve")` e adicionar `start_position = Vector2(600, 0)` (mesmo ponto da Fase 1, agora explícito).

- [ ] **Step 2: Adicionar `Corredor2` e `Corredor3` via MCP `add_node`**

Disposição radial a 120° uma da outra, mesmo raio de `Corredor1` (600px), convergindo todas em `(0, 0)` (posição do `Mago`):
- `Corredor2`: ângulo 120° → `start_position = Vector2(-300, 520)`.
- `Corredor3`: ângulo 240° → `start_position = Vector2(-300, -520)`.

`add_node` (`parentNodePath="root"`, `nodeType="Path2D"`, `nodeName="Corredor2"`).
`add_node` (`parentNodePath="root/Corredor2"`, `nodeType="Timer"`, `nodeName="SpawnTimer"`).
`add_node` (`parentNodePath="root"`, `nodeType="Path2D"`, `nodeName="Corredor3"`).
`add_node` (`parentNodePath="root/Corredor3"`, `nodeType="Timer"`, `nodeName="SpawnTimer"`).

- [ ] **Step 3: Atribuir script, `enemy_scene` e `start_position` aos dois novos nós via `Edit`**

No bloco de `Corredor2`: `script = ExtResource("corredor_script")`, `enemy_scene = ExtResource("enemy_scene")`, `start_position = Vector2(-300, 520)`.
No bloco de `Corredor3`: `script = ExtResource("corredor_script")`, `enemy_scene = ExtResource("enemy_scene")`, `start_position = Vector2(-300, -520)`.

- [ ] **Step 4: Salvar e verificar**

`save_scene` (`scenePath="scenes/main.tscn"`). Ler o arquivo e confirmar: nenhum `corredor1_curve` sobrando, `Corredor1` com `start_position = Vector2(600, 0)` e sem `curve =`, `Corredor2`/`Corredor3` cada um com `script`, `enemy_scene`, `start_position` corretos e `SpawnTimer` filho.

- [ ] **Step 5: Verificação manual — 3 lanes nascem e convergem ao centro**

`run_project`. Aguardar >2s e confirmar visualmente que inimigos nascem nas 3 direções (leste, e os outros dois pontos a ±120°) e todos convergem andando até o centro onde está o `Mago`; `get_debug_output` sem erro; `stop_project`.

- [ ] **Step 6: Commit**

```bash
git add scenes/main.tscn
git commit -m "feat: adiciona Corredor2 e Corredor3 em disposicao radial"
```

---

## Task 4: Câmera, verificação end-to-end e fechamento da fase

**Files:**
- Modify: `scenes/main.tscn` (`Camera2D.zoom`)
- Modify: `docs/roadmap.md`

**Interfaces:**
- Consumes: todos os sistemas das Tasks 1–3.

- [ ] **Step 1: Ajustar `Camera2D.zoom` via `Edit`**

Ler `scenes/main.tscn`. No bloco `[node name="Camera2D" type="Camera2D" parent="."]`, adicionar `zoom = Vector2(0.6, 0.6)`.

Minha decisão (skill `camera-system`): `zoom < 1` em `Camera2D` mostra *mais* área do mundo (zoom "out"). Com viewport 1280×720 (metade: 640×360) e `zoom = 0.6`, a área visível passa a ~1067×1200 de meia-extensão (640/0.6 × 360/0.6), suficiente para enquadrar os 3 pontos de spawn em raio 600 (o mais distante verticalmente é `y = ±520`, bem dentro da meia-altura visível de 600) sem mover a câmera — atende a `design-system.md` ("todos os corredores visíveis simultaneamente, sem scroll").

- [ ] **Step 2: Salvar**

`save_scene` (`scenePath="scenes/main.tscn"`).

- [ ] **Step 3: Verificação manual — todos os corredores visíveis sem scroll (Review Focus)**

`run_project`. Confirmar visualmente que os 3 pontos de nascimento de inimigo (leste, e os dois a ±120°) ficam dentro da área visível da janela 1280×720 o tempo todo, sem a câmera se mover; `stop_project`. Pedir confirmação visual do usuário.

- [ ] **Step 4: Verificação manual — mira de área acerta inimigos de corredores diferentes (Review Focus)**

`run_project`. Esperar inimigos de pelo menos 2 corredores diferentes ficarem próximos um do outro perto do centro (dentro do raio de 80px da magia — mais fácil perto da torre, onde as 3 lanes convergem). Clicar entre eles e confirmar visualmente que ambos tomam dano/morrem na mesma conjuração. `get_debug_output` sem erro; `stop_project`.

- [ ] **Step 5: Verificação manual — variedade de tier aparece (Review Focus)**

`run_project`. Deixar rodar tempo suficiente (múltiplos spawns nos 3 corredores) e confirmar visualmente que as 4 cores (branco, verde, azul, vermelho) aparecem pelo menos uma vez cada. Se o vermelho (peso 3/100) não aparecer num tempo razoável, aumentar temporariamente `TIER_WEIGHTS` em `corredor.gd` (ex. `[25.0, 25.0, 25.0, 25.0]`) só para confirmar que o tier 3 é alcançável, depois reverter para `[60.0, 25.0, 12.0, 3.0]` antes do commit. `stop_project`.

- [ ] **Step 6: Verificação manual — vida da base e pausa com 3 spawners simultâneos (Review Focus)**

Reduzir temporariamente `Base.MAX_LIFE` para `10.0` (reverter depois, mesmo truque da Fase 1). `run_project`, deixar inimigos de qualquer corredor chegarem à base sem matar nenhum até a vida zerar. Confirmar: `GameOverLabel` fica visível, o jogo pausa (todos os 3 `SpawnTimer`/inimigos param), `get_debug_output` sem erro. `stop_project`. Reverter `MAX_LIFE` para `100.0` antes do commit.

- [ ] **Step 7: Verificação manual — regressão do tier 0 (Review Focus)**

`run_project`. Confirmar que um inimigo branco (tier 0, a maioria dos spawns) continua morrendo com 1 acerto de magia (`SPELL_DAMAGE` 50 == `MAX_HP * TIER_HP_MULT[0]` = 50) e mantém a cor branca nativa. `stop_project`.

- [ ] **Step 8: Atualizar `docs/roadmap.md`**

Trocar a linha "Estado atual do projeto: Fase 1 concluída... Próxima fase: Fase 2." para refletir Fase 2 concluída (3 corredores radiais fixos, tier de cor via shader com proporção fixa) e Fase 3 como próxima, citando este plano. Registrar explicitamente que a escalada de nº de lanes por marco de progressão do save (mencionada pelo usuário ao iniciar esta fase) continua pendente para fase futura de progressão entre dias (Fase 6/7), não implementada aqui.

- [ ] **Step 9: Commit**

```bash
git add scenes/main.tscn docs/roadmap.md
git commit -m "feat: ajusta camera para radial de 3 lanes e conclui fase 2"
```
