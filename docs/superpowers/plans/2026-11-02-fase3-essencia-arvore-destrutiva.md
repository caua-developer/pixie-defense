# Fase 3 — Essência + Árvore Destrutiva (1 árvore) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de criar/editar qualquer nó ou script Godot, re-consulte o card GodotPrompter pela skill `godot-prompter:*` correspondente (este plano já consultou `godot-ui` — ver decisões abaixo). `CLAUDE.md` Regra 1 tem precedência sobre qualquer recomendação de abstração maior dessas skills.

**Goal:** Inimigos mortos dropam fragmentos de essência (conversão 10:1 em essência inteira); o jogador abre um painel pela HUD que pausa o combate e permite comprar, com essência acumulada, até 4 upgrades fixos e independentes da magia já existente (dano, cooldown, custo de mana, raio).

**Architecture:** Um novo nó `EssenceTracker` (script direto, sem autoload) guarda `fragments`/`essence` e é localizado pelo mesmo padrão já usado para `base`/`inimigos` (`get_tree().get_first_node_in_group(...)`) — `enemy.gd` já usa esse padrão para achar a base, então reaproveitar a convenção em vez de introduzir um EventBus. `mago.gd` troca suas 4 consts de magia por `var` com 4 métodos públicos de upgrade (mesmo padrão que `enemy.gd` já fez na Fase 2 ao trocar `const` por `var` ajustável via `set_tier`). Um novo `skill_tree_panel.gd`, anexado a um `PanelContainer` na cena principal (sibling da `HUD`, não dentro dela, pra não ser afetado pelo `mouse_filter` do `Root`), lista os 4 nós fixos como dados diretos no próprio script (arrays paralelos de nome/custo), sem `Resource` genérico de nó de árvore — só há 4 nós fixos nesta fase e as outras 2 árvores (Fase 4) ainda não justificam uma abstração compartilhada. O painel usa `process_mode = PROCESS_MODE_ALWAYS` (decisão da skill `godot-ui`, seção "Common UI Patterns" / checklist) para continuar recebendo clique de botão enquanto `get_tree().paused = true`.

**Tech Stack:** Godot 4.7 (GL Compatibility), GDScript com tipagem estática, edição de cena via MCP `godot` (`add_node`, `save_scene`, `run_project`, `get_debug_output`, `stop_project`) com fallback para `Edit` direto no `.tscn` nos casos que o MCP não cobre (propriedades de layout, scripts, valores exatos).

**Spec:** `docs/roadmap.md` (seção "Fase 3 — Essência + árvore de habilidade"), `docs/project-context.md` (pilares 5 e 6, passo 7 do loop de sessão), `docs/balancing.md` (seção "Economia de essência" — conversão 10:1 e hipótese de drop por tier).

## Global Constraints

- Godot 4.7, renderer GL Compatibility; GDScript com tipagem estática em todo script novo/modificado.
- Cena principal fixa: `res://scenes/main.tscn`.
- **Conversão de essência fixa em `balancing.md`:** 10 fragmentos = 1 essência.
- **Drop de fragmento por tier (hipótese de `balancing.md`, a calibrar na Fase 10):** branco=1, verde=2, azul=4, vermelho=6 (usando o piso da faixa "6–8" do documento — valor único mais simples pra esta fase, hipótese do implementador).
- **4 nós fixos, sem pré-requisitos entre eles, custo crescente em essência inteira (decisão do usuário nesta sessão):** Dano+ (1), Cooldown- (2), Custo de Mana- (3), Raio+ (4). Cada nó compra uma única vez.
- **Magnitude de cada upgrade (hipótese do implementador, a calibrar na Fase 10):** ±20% sobre o valor atual (multiplicador 1.2 para aumento, 0.8 para redução), aplicado uma vez por nó (nós não são recompráveis nesta fase).
- Anti-over-engineering (`CLAUDE.md` Regra 1): sem autoload/EventBus/manager/`Resource` genérico de nó de árvore/`state machine` nesta fase. Os 4 nós ficam como arrays paralelos diretos em `skill_tree_panel.gd` — a Fase 4 (quando existirem 3 árvores) é o ponto certo para reavaliar se vale a pena um formato de dado compartilhado, não antes.
- Especialização de save **não** entra nesta fase (fica para a Fase 4, quando as 3 árvores existirem) — a árvore Destrutiva é a única disponível e sempre ativa.
- Sem framework de teste automatizado nesta fase (mesma decisão herdada das Fases 1 e 2: validação é perceptual/funcional via MCP, não unit-testável). Verificação via `run_project` + `get_debug_output` e `godot --headless --check-only --script <arquivo>` para sintaxe, usando `C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`.
- Escopo travado pelo `roadmap.md`: **fora desta fase** — árvores Defensiva/Maldição, traços cruzados de essência de boss, boss/mini-boss, escolha de especialização no save, economia de dinheiro, geração procedural, modos de dificuldade.

## Review Focus

- **Conversão de fragmento em essência não perde nem duplica unidades na borda exata de 10** (ex.: 9→10 fragmentos deve virar 1 essência + 0 fragmentos, não 1 essência + 10 ou ficar em 10 fragmentos sem converter). Verificado na Task 1 Step 8.
- **Comprar um nó sem essência suficiente não desconta essência nem aplica o upgrade** (botão deve ficar desabilitado ou o clique deve ser ignorado silenciosamente). Verificado na Task 3 Step 8.
- **Um nó já comprado não pode ser comprado de novo** (clique repetido no mesmo botão não deve descontar essência duas vezes nem dobrar o upgrade). Verificado na Task 3 Step 8.
- **Abrir/fechar a árvore repetidamente pausa e despausa corretamente a cada vez** (sem o jogo ficar travado pausado após fechar, nem o painel reabrir já pausado incorretamente na primeira vez). Verificado na Task 3 Step 9.
- **Multi-kill numa única conjuração (mira de área acertando 2+ inimigos, pilar da Fase 1/2) ainda dropa fragmento de cada inimigo morto independentemente**, não só do primeiro. Verificado na Task 1 Step 8.

---

## Task 1: `EssenceTracker` (fragmentos + conversão) e drop ao matar inimigo

**Files:**
- Create: `scripts/essence_tracker.gd`
- Modify: `scripts/enemy.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`

**Interfaces:**
- Produces: `EssenceTracker.fragments: int`, `EssenceTracker.essence: int`, `EssenceTracker.add_fragments(amount: int) -> void`; grupo `"essencia"` (mesmo padrão de lookup usado para `"base"`). Task 3 lê/escreve `essence` diretamente e Task 2/3 dependem desse grupo para localizar o tracker.
- Consumes: nenhuma interface nova de outra task; usa o grupo `"base"` já existente apenas como referência de padrão.

- [ ] **Step 1: Criar `scripts/essence_tracker.gd`**

```gdscript
extends Node

const FRAGMENTS_PER_ESSENCE: int = 10

var fragments: int = 0
var essence: int = 0

func _ready() -> void:
	add_to_group("essencia")

func add_fragments(amount: int) -> void:
	fragments += amount
	while fragments >= FRAGMENTS_PER_ESSENCE:
		fragments -= FRAGMENTS_PER_ESSENCE
		essence += 1
```

Minha decisão: `while` (não `if`) na conversão cobre o caso de um drop único maior que 10 fragmentos de uma vez (ex.: dois vermelhos de 6 matos no mesmo frame por conjurações diferentes somando 12) sem perder o excedente — é o caso da Review Focus de borda exata.

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/essence_tracker.gd`
Expected: sem erro.

- [ ] **Step 3: Modificar `scripts/enemy.gd` — armazenar tier e dropar fragmentos na morte**

Adicionar, após as consts de tier já existentes:

```gdscript
# Índices: 0 branco, 1 verde, 2 azul, 3 vermelho — mesma ordem de TIER_HP_MULT
const FRAGMENT_DROP: Array[int] = [1, 2, 4, 6]  # hipótese — calibrar na Fase 10 (balancing.md)
```

Adicionar `var tier: int = 0` junto das outras `var` de instância. Em `set_tier(tier: int) -> void`, adicionar `self.tier = tier` como primeira linha (disambigua o parâmetro do campo de instância de mesmo nome).

Reescrever `take_damage`:

```gdscript
func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		_drop_fragments()
		queue_free()

func _drop_fragments() -> void:
	var tracker := get_tree().get_first_node_in_group("essencia")
	if tracker:
		tracker.add_fragments(FRAGMENT_DROP[tier])
```

- [ ] **Step 4: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/enemy.gd`
Expected: sem erro.

- [ ] **Step 5: Adicionar nó `EssenceTracker` em `scenes/main.tscn` via MCP `add_node` + `Edit`**

`add_node` (`parentNodePath="root"`, `nodeType="Node"`, `nodeName="EssenceTracker"`). Depois, via `Edit`, adicionar o `ext_resource` do script (`[ext_resource type="Script" path="res://scripts/essence_tracker.gd" id="essence_tracker_script"]`) e `script = ExtResource("essence_tracker_script")` no bloco do nó.

- [ ] **Step 6: Adicionar `EssenceLabel` em `scenes/main.tscn` via MCP `add_node`**

`add_node` (`parentNodePath="root/HUD/Root/VBox"`, `nodeType="Label"`, `nodeName="EssenceLabel"`). Definir `text = "Essência: 0 (Fragmentos: 0/10)"` via `Edit`.

- [ ] **Step 7: Salvar cena, atualizar `scripts/main.gd` e verificar**

`save_scene` (`scenePath="scenes/main.tscn"`). Em `scripts/main.gd`, adicionar:

```gdscript
@onready var essence_tracker: Node = $EssenceTracker
@onready var essence_label: Label = $HUD/Root/VBox/EssenceLabel
```

E em `_process`, adicionar:

```gdscript
essence_label.text = "Essência: %d (Fragmentos: %d/10)" % [essence_tracker.essence, essence_tracker.fragments]
```

Verificar sintaxe: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/main.gd` — Expected: sem erro.

- [ ] **Step 8: Verificação manual — drop, conversão exata e multi-kill (Review Focus)**

`run_project`. Matar inimigos brancos (1 clique de magia cada, `SPELL_DAMAGE` 50) e observar `EssenceLabel`: cada morte branca deve somar 1 fragmento; ao acumular o 10º fragmento, o label deve mostrar "Essência: 1 (Fragmentos: 0/10)" no mesmo frame (não "10/10"). Tentar também um multi-kill (clicar num ponto onde 2+ inimigos de corredores diferentes estão próximos, pilar da Fase 2) e confirmar que o total de fragmentos sobe pela soma de todos os mortos naquela conjuração, não só 1. `get_debug_output` sem erro. `stop_project`.

- [ ] **Step 9: Commit**

```bash
git add scripts/essence_tracker.gd scripts/enemy.gd scripts/main.gd scenes/main.tscn
git commit -m "feat: adiciona rastreador de essencia e drop de fragmentos ao matar inimigo"
```

---

## Task 2: Upgrades da magia em `mago.gd`

**Files:**
- Modify: `scripts/mago.gd`

**Interfaces:**
- Produces: `Mago.upgrade_damage() -> void`, `Mago.reduce_cooldown() -> void`, `Mago.reduce_mana_cost() -> void`, `Mago.increase_radius() -> void`; vars `spell_damage: float`, `spell_cooldown: float`, `spell_cost: float`, `spell_radius: float` (antes consts `SPELL_DAMAGE`/`SPELL_COOLDOWN`/`SPELL_COST`/`SPELL_RADIUS`); grupo `"mago"` via novo `_ready()`. Task 3 chama os 4 métodos de upgrade e localiza o `Mago` pelo grupo `"mago"`.
- Consumes: nenhuma interface de outra task.

- [ ] **Step 1: Reescrever as consts/vars e adicionar `_ready` e os 4 métodos em `scripts/mago.gd`**

Substituir o bloco de consts no topo por:

```gdscript
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
```

Adicionar `func _ready() -> void: add_to_group("mago")` e os 4 métodos:

```gdscript
func upgrade_damage() -> void:
	spell_damage *= DAMAGE_UPGRADE_MULT

func reduce_cooldown() -> void:
	spell_cooldown *= COOLDOWN_UPGRADE_MULT

func reduce_mana_cost() -> void:
	spell_cost *= MANA_COST_UPGRADE_MULT

func increase_radius() -> void:
	spell_radius *= RADIUS_UPGRADE_MULT
```

- [ ] **Step 2: Substituir os usos das consts antigas pelas vars novas**

Em `_try_cast`, `_physics_process` e `_spawn_spell_effect`, trocar toda referência a `SPELL_COST`→`spell_cost`, `SPELL_COOLDOWN`→`spell_cooldown`, `SPELL_RADIUS`→`spell_radius`, `SPELL_DAMAGE`→`spell_damage`. Nenhuma outra lógica muda.

- [ ] **Step 3: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/mago.gd`
Expected: sem erro.

- [ ] **Step 4: Verificação manual — regressão (magia funciona igual à Fase 2 sem nenhum upgrade comprado)**

`run_project`. Confirmar que conjurar a magia continua custando a mesma mana visível no `ManaLabel`, com o mesmo cooldown e raio percebidos de antes (nenhum upgrade foi comprado ainda, então `spell_*` == `BASE_SPELL_*`). `get_debug_output` sem erro. `stop_project`.

- [ ] **Step 5: Verificação manual temporária — cada método de upgrade tem efeito visível**

Adicionar temporariamente ao final de `_ready()`: `upgrade_damage(); reduce_cooldown(); reduce_mana_cost(); increase_radius()`. `run_project`, confirmar visualmente que o cooldown entre conjurações é visivelmente menor, o raio do efeito visual (`spell_effect.gd`) é maior, e a mana gasta por conjuração (visível no `ManaLabel`) é menor que 25. `get_debug_output` sem erro. `stop_project`. Remover as 4 linhas temporárias antes do próximo step.

- [ ] **Step 6: Commit**

```bash
git add scripts/mago.gd
git commit -m "feat: converte stats de magia do mago em vars com metodos de upgrade"
```

---

## Task 3: Painel da árvore Destrutiva (UI + pausa + compra de nós)

**Files:**
- Create: `scripts/skill_tree_panel.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: `EssenceTracker.essence` / grupo `"essencia"` (Task 1); `Mago.upgrade_damage()`, `Mago.reduce_cooldown()`, `Mago.reduce_mana_cost()`, `Mago.increase_radius()` / grupo `"mago"` (Task 2).
- Produces: `SkillTreePanel.open() -> void`, `SkillTreePanel.close() -> void` (chamados pelo botão da HUD e pelo botão de fechar dentro do próprio painel).

- [ ] **Step 1: Criar `scripts/skill_tree_panel.gd`**

```gdscript
extends PanelContainer

const NODE_COUNT: int = 4
const NODE_NAMES: Array[String] = ["Dano+", "Cooldown-", "Custo de Mana-", "Raio+"]
const NODE_COSTS: Array[int] = [1, 2, 3, 4]

var purchased: Array[bool] = [false, false, false, false]

@onready var mago: Node2D = get_tree().get_first_node_in_group("mago")
@onready var essence_tracker: Node = get_tree().get_first_node_in_group("essencia")
@onready var node_labels: Array[Label] = [
	$VBox/Node1Row/Node1Label, $VBox/Node2Row/Node2Label,
	$VBox/Node3Row/Node3Label, $VBox/Node4Row/Node4Label,
]
@onready var node_buttons: Array[Button] = [
	$VBox/Node1Row/Node1Button, $VBox/Node2Row/Node2Button,
	$VBox/Node3Row/Node3Button, $VBox/Node4Row/Node4Button,
]
@onready var close_button: Button = $VBox/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for i in NODE_COUNT:
		node_buttons[i].pressed.connect(_on_node_pressed.bind(i))
	close_button.pressed.connect(close)
	_update_labels()

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _on_node_pressed(index: int) -> void:
	if purchased[index] or essence_tracker.essence < NODE_COSTS[index]:
		return
	essence_tracker.essence -= NODE_COSTS[index]
	purchased[index] = true
	match index:
		0: mago.upgrade_damage()
		1: mago.reduce_cooldown()
		2: mago.reduce_mana_cost()
		3: mago.increase_radius()
	_update_labels()

func _update_labels() -> void:
	for i in NODE_COUNT:
		var status: String = "comprado" if purchased[i] else "%d essência(s)" % NODE_COSTS[i]
		node_labels[i].text = "%s — %s" % [NODE_NAMES[i], status]
		node_buttons[i].disabled = purchased[i]
```

Minha decisão (skill `godot-ui`, checklist "Pause menu root `Control` has `process_mode = PROCESS_MODE_ALWAYS`"): só a raiz (`PanelContainer`) recebe `PROCESS_MODE_ALWAYS` explicitamente — os filhos (`VBoxContainer`, `Button`, `Label`) ficam no default `PROCESS_MODE_INHERIT`, que herda o modo do pai na cadeia de pausa, então os botões continuam clicáveis com `get_tree().paused = true` sem precisar setar o modo em cada um.

Minha decisão (Regra 1 do `CLAUDE.md`): os 4 nós ficam como 3 arrays paralelos fixos (`NODE_NAMES`, `NODE_COSTS`, `purchased`) direto no script da UI, sem uma classe/`Resource` de "nó de árvore" — com só 1 árvore e 4 nós fixos nesta fase, uma abstração de nó genérico não tem um segundo consumidor real ainda (só surge na Fase 4 com as outras 2 árvores).

- [ ] **Step 2: Verificar sintaxe**

Run: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/skill_tree_panel.gd`
Expected: sem erro.

- [ ] **Step 3: Adicionar `SkillTreeButton` na HUD via MCP `add_node`**

`add_node` (`parentNodePath="root/HUD/Root/VBox"`, `nodeType="Button"`, `nodeName="SkillTreeButton"`). Via `Edit`, definir `text = "Árvore"`.

- [ ] **Step 4: Adicionar a estrutura do `SkillTreePanel` via MCP `add_node`**

Sequência de `add_node`, todos com `parentNodePath="root"` para o painel raiz e os caminhos filhos correspondentes abaixo:
- `add_node` (`parentNodePath="root"`, `nodeType="PanelContainer"`, `nodeName="SkillTreePanel"`).
- `add_node` (`parentNodePath="root/SkillTreePanel"`, `nodeType="VBoxContainer"`, `nodeName="VBox"`).
- Para cada `i` em 1..4: `add_node` (`parentNodePath="root/SkillTreePanel/VBox"`, `nodeType="HBoxContainer"`, `nodeName="Node{i}Row"`); dentro dele, `add_node` (`nodeType="Label"`, `nodeName="Node{i}Label"`) e `add_node` (`nodeType="Button"`, `nodeName="Node{i}Button"`, `text="Comprar"`).
- `add_node` (`parentNodePath="root/SkillTreePanel/VBox"`, `nodeType="Button"`, `nodeName="CloseButton"`, `text="Fechar"`).

- [ ] **Step 5: Ajustar propriedades do `SkillTreePanel` e ligar script via `Edit`**

Ler `scenes/main.tscn`. No bloco `[node name="SkillTreePanel" ...]`, adicionar:

```
script = ExtResource("skill_tree_panel_script")
visible = false
layout_mode = 3
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
grow_horizontal = 2
grow_vertical = 2
custom_minimum_size = Vector2(320, 220)
```

Adicionar o `ext_resource` do script no topo: `[ext_resource type="Script" path="res://scripts/skill_tree_panel.gd" id="skill_tree_panel_script"]`.

Minha decisão (skill `godot-ui`, "Anchor Presets" — Center): `anchors_preset = 8` com os 4 anchors em 0.5 centraliza o painel na tela independente da resolução, sem precisar de `ScrollContainer`/`responsive-ui` nesta fase (painel pequeno, cabe em qualquer resolução suportada hoje).

- [ ] **Step 6: Ligar o botão da HUD ao painel via `Edit` em `scripts/main.gd`**

Em `scripts/main.gd`, adicionar:

```gdscript
@onready var skill_tree_button: Button = $HUD/Root/VBox/SkillTreeButton
@onready var skill_tree_panel: PanelContainer = $SkillTreePanel
```

E em `_ready()`, adicionar: `skill_tree_button.pressed.connect(skill_tree_panel.open)`.

- [ ] **Step 7: Salvar e verificar**

`save_scene` (`scenePath="scenes/main.tscn"`). Ler o arquivo e confirmar: `SkillTreeButton` dentro de `HUD/Root/VBox`, `SkillTreePanel` como filho direto de `Main` com `script`/anchors/`custom_minimum_size` corretos, 4 `NodeXRow` com `Label`+`Button` e `CloseButton` dentro de `VBox`. Verificar sintaxe de `scripts/main.gd`: `"C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --check-only --script scripts/main.gd` — Expected: sem erro.

- [ ] **Step 8: Verificação manual — compra bloqueada sem essência e idempotência (Review Focus)**

`run_project`. Clicar em "Árvore" assim que o jogo começa (essência = 0): confirmar que os 4 botões "Comprar" não têm efeito (nenhuma essência negativa, nenhum upgrade aplicado — testável fechando o painel e observando que o cooldown/raio/custo de mana não mudaram). Matar inimigos até acumular essência suficiente para o nó mais barato (Dano+, custo 1), comprá-lo, confirmar que o label muda para "comprado" e o botão fica desabilitado; clicar novamente no mesmo botão (mesmo que o `disabled` já bloqueie, confirmar via leitura do `essence_tracker.essence` que não há segundo desconto). `get_debug_output` sem erro. `stop_project`.

- [ ] **Step 9: Verificação manual — abrir/fechar repetidamente pausa e despausa corretamente (Review Focus)**

`run_project`. Abrir e fechar o painel (botão "Árvore" / botão "Fechar") pelo menos 3 vezes em sequência, confirmando a cada abertura que inimigos/`SpawnTimer` param de se mover e a cada fechamento que voltam a se mover normalmente. `get_debug_output` sem erro. `stop_project`.

- [ ] **Step 10: Atualizar `docs/roadmap.md`**

Trocar a linha "Estado atual do projeto: Fase 2 concluída... Próxima fase: Fase 3." para refletir Fase 3 concluída (fragmentos de essência com conversão 10:1, 4 nós fixos da árvore Destrutiva comprados via painel que pausa o jogo) e Fase 4 como próxima, citando este plano.

- [ ] **Step 11: Commit**

```bash
git add scripts/skill_tree_panel.gd scripts/main.gd scenes/main.tscn docs/roadmap.md
git commit -m "feat: adiciona painel da arvore destrutiva com 4 nos de upgrade"
```
