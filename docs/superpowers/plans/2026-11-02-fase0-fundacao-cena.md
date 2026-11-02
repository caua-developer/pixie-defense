# Fase 0 — Fundação da Cena Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Before writing or editing any Godot node/scene, re-check the GodotPrompter card for a matching `godot-prompter:*` skill (this plan already consulted `camera-system`; `criacao-projeto-2d` governs the actual MCP scene edits per `CLAUDE.md`).

**Goal:** `res://scenes/main.tscn` carrega, o mago aparece estático no centro da cena, e a câmera fica fixa em vista de cima — sem combate, inimigos ou UI.

**Architecture:** `scenes/main.tscn` já existe com `Main` (Node2D) e um `Camera2D` filho. Este plano adiciona um nó `Mago` (Node2D) com um visual placeholder (`Polygon2D`) no centro, configura o `Camera2D` existente como fixo/ativo, e define a resolução de viewport em `project.godot`. Nenhum script GDScript é criado — não há lógica nesta fase (Regra 1 do `CLAUDE.md`: nada além do mínimo pedido).

**Tech Stack:** Godot 4.7 (GL Compatibility), edição de cena via MCP `godot` (tools `add_node`, `load_sprite` se aplicável, `save_scene`, `run_project`, `get_debug_output`, `stop_project`).

**Spec:** `docs/project-context.md` (visão geral), `docs/roadmap.md` (seção "Fase 0 — Fundação da cena"), `docs/design-system.md` (topologia radial, composição de cena).

## Global Constraints

- Godot 4.7, renderer GL Compatibility (`config/features=PackedStringArray("4.7", "GL Compatibility")`).
- Cena principal fixa: `res://scenes/main.tscn` (`run/main_scene`).
- Anti-over-engineering (`CLAUDE.md` Regra 1): nenhum manager/EventBus/state machine/Resource de configuração nesta fase — não há mapeamento de fase futura que justifique.
- Escopo travado pelo `roadmap.md`: **fora desta fase** — multi-lane, árvores de habilidade, essência/dinheiro, geração procedural, VHS shader, mini-boss/boss, combate, inimigos, UI.
- Topologia radial (`design-system.md`): torre (mago) no centro da tela, vista de cima — toda a composição futura parte desse centro.

## Review Focus

- **Resolução de viewport não definida** (`project.godot` não tem `window/size/viewport_width`/`height`): sem isso, a janela abre no tamanho default do Godot, que pode não ficar centrada da forma esperada. Tarefa que define a resolução verifica o valor salvo.
- **Câmera sem `current = true`**: se o `Camera2D` existente não for marcado como ativo, o Godot pode logar aviso de "no active camera" ou renderizar a partir da origem padrão em vez do centro pretendido. Verificado ao rodar o projeto e checar `get_debug_output`.
- **Nó `Mago` fora do centro exato**: um erro de digitação na posição (ex.: esquecer de zerar `position`) deixaria o mago fora do centro, quebrando a validação visual da fase. Verificado inspecionando a propriedade salva no `.tscn`.
- **Mudanças de cena feitas via MCP sem `save_scene`**: o `run_project` rodaria a versão antiga do arquivo. Toda tarefa que edita o `.tscn` via MCP termina com `save_scene` antes de rodar o projeto.
- **Erros silenciosos do MCP** (`add_node` com `parentNodePath` errado): o tool pode falhar sem quebrar o fluxo visivelmente. Cada passo de edição de nó é seguido por leitura do `.tscn` (ou `get_project_info`) para confirmar que o nó foi realmente criado no caminho esperado.

---

## Task 1: Resolução de viewport para vista de cima

**Files:**
- Modify: `project.godot` (seção `[display]`)

**Interfaces:**
- Produces: resolução base `1280x720` (16:9), que as tarefas seguintes (câmera, posicionamento do mago) assumem como referência de "centro da tela" = `(640, 360)` em coordenadas de viewport, mas `(0, 0)` em coordenadas de mundo (origem da cena, ver Task 2/3).

- [ ] **Step 1: Adicionar `window/size/viewport_width=1280` e `window/size/viewport_height=720` na seção `[display]` de `project.godot`**

Minha decisão: 1280x720 (16:9) como resolução base — nenhum valor estava definido no `project.godot` atual e nada no design travou uma resolução específica. `window/stretch/mode="canvas_items"` e `window/stretch/aspect="expand"` já existentes continuam valendo.

- [ ] **Step 2: Verificar o arquivo**

Ler `project.godot` e confirmar que a seção `[display]` contém as duas chaves com os valores `1280` e `720`.

- [ ] **Step 3: Commit**

```bash
git add project.godot
git commit -m "config: define viewport 1280x720 para vista de cima"
```

---

## Task 2: Nó Mago estático no centro da cena

**Files:**
- Modify: `scenes/main.tscn` (via MCP `godot`)

**Interfaces:**
- Consumes: cena `res://scenes/main.tscn` já existente com root `Main` (Node2D).
- Produces: nó `Mago` (Node2D) em `root/Mago`, posição `(0, 0)` — este é o ponto de referência central que a Task 3 (câmera) e todas as fases futuras (corredores radiais ao redor da torre) usam como origem.

- [ ] **Step 1: Adicionar o nó `Mago` (Node2D) como filho de `root`**

Via MCP `mcp__godot__add_node`: `projectPath` = raiz do projeto, `scenePath` = `scenes/main.tscn`, `nodeType` = `Node2D`, `nodeName` = `Mago`, `parentNodePath` = `root`, `properties` = `{"position": {"x": 0, "y": 0}}`.

- [ ] **Step 2: Adicionar um visual placeholder (`Polygon2D`) como filho de `Mago`**

Via MCP `mcp__godot__add_node`: `parentNodePath` = `root/Mago`, `nodeType` = `Polygon2D`, `nodeName` = `Placeholder`, `properties` com `polygon` = quadrado 32×32 centrado na origem, pontos exatos `[[-16,-16],[16,-16],[16,16],[-16,16]]`, e `color` = `Color(0.85, 0.85, 1.0, 1.0)` (lavanda claro).

Minha decisão: forma e cor são placeholder deliberado — branco puro é reservado ao tier 0 de inimigos (`design-system.md`), então uso um tom levemente lavanda pra não ambiguar visualmente antes mesmo dos inimigos existirem. Sprite real (`assets/characters/People.png`) fica para uma fase de arte posterior, pois o recorte exato do frame do mago na spritesheet ainda não foi decidido (fora do escopo desta fase).

- [ ] **Step 3: Salvar a cena**

`mcp__godot__save_scene` com `scenePath` = `scenes/main.tscn`.

- [ ] **Step 4: Verificar a árvore de nós salva**

Ler `scenes/main.tscn` e confirmar: existe `[node name="Mago" type="Node2D" parent="."]` com `position = Vector2(0, 0)` (ou ausente, o que implica default `(0,0)`), e `[node name="Placeholder" type="Polygon2D" parent="Mago"]` com o `polygon` e `color` esperados.

- [ ] **Step 5: Commit**

```bash
git add scenes/main.tscn
git commit -m "feat: adiciona mago estatico placeholder no centro da cena"
```

---

## Task 3: Câmera fixa em vista de cima

**Files:**
- Modify: `scenes/main.tscn` (via MCP `godot`)

**Interfaces:**
- Consumes: `Camera2D` já existente em `root/Camera2D` (ver Task 2 para a origem `(0,0)` do `Mago`).
- Produces: câmera ativa (`current = true`), posicionada em `(0, 0)` — coincide com o centro do `Mago`, estabelecendo o ponto focal fixo que a topologia radial (`design-system.md`) usa em todas as fases seguintes.

- [ ] **Step 1: Configurar o `Camera2D` existente**

Via MCP, atualizar as propriedades do nó `root/Camera2D`: `position` = `(0, 0)`, `current` = `true`, `zoom` = `(1, 1)`. (O MCP `godot` não lista um tool dedicado de "set node properties" além de `add_node`; se não houver tool de edição direta de propriedades de nó existente, editar `scenes/main.tscn` diretamente com a ferramenta `Edit`, adicionando `position = Vector2(0, 0)`, `zoom = Vector2(1, 1)` e `current = true` ao bloco `[node name="Camera2D" ...]`.)

Minha decisão: `zoom = (1,1)` é o ponto de partida — a calibração fina do zoom pra enquadrar os corredores radiais só faz sentido a partir da Fase 2, quando os corredores existirem (`design-system.md` já marca intensidade/composição final como "a calibrar em protótipo").

- [ ] **Step 2: Salvar a cena (se editado via MCP) ou confirmar o arquivo (se editado via `Edit`)**

Se usado `mcp__godot__save_scene`, chamar com `scenePath` = `scenes/main.tscn`. Se editado diretamente, a gravação já ocorreu via `Edit`.

- [ ] **Step 3: Verificar**

Ler `scenes/main.tscn` e confirmar que o bloco `[node name="Camera2D" ...]` tem `current = true`.

- [ ] **Step 4: Commit**

```bash
git add scenes/main.tscn
git commit -m "feat: fixa camera central ativa para vista de cima"
```

---

## Task 4: Verificação end-to-end em runtime

**Files:**
- None (apenas execução via MCP)

**Interfaces:**
- Consumes: resultado das Tasks 1–3 (`project.godot`, `scenes/main.tscn` completos).

- [ ] **Step 1: Rodar o projeto**

`mcp__godot__run_project` com `projectPath` = raiz do projeto.

- [ ] **Step 2: Checar saída de debug**

`mcp__godot__get_debug_output`. Esperado: nenhum erro/warning sobre câmera ausente, nó inválido, ou script faltando. (Como não há script nesta fase, qualquer erro de script indicaria um passo anterior malfeito.)

- [ ] **Step 3: Parar o projeto**

`mcp__godot__stop_project`.

- [ ] **Step 4: Confirmação visual manual**

Reportar ao usuário: cena carregou, Mago (placeholder lavanda) centralizado, câmera fixa sem erros — pedir confirmação visual dele antes de considerar a Fase 0 concluída (não há teste automatizado de renderização nesta fase, é validação humana).

- [ ] **Step 5: Atualizar `docs/roadmap.md`**

Marcar a Fase 0 como concluída (ex.: trocar a linha "Estado atual do projeto: scaffold vazio... Nenhuma fase abaixo foi iniciada." por um estado que reflita Fase 0 concluída e Fase 1 como próxima).

- [ ] **Step 6: Commit**

```bash
git add docs/roadmap.md
git commit -m "docs: marca Fase 0 como concluida"
```
