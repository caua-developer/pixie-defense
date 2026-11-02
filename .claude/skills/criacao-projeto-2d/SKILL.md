---
name: criacao-projeto-2d
description: Use ao criar ou alterar cenas e nós 2D neste projeto Godot (nova cena, novo nó, sprite, estrutura de cena). Faz isso pelo MCP godot e mantém a arquitetura simples.
---

# Criação de Cenas/Nós 2D via MCP

## Ferramentas (MCP `godot`, projectPath = raiz deste repo)
- `create_scene` (scenePath, rootNodeType): cria a `.tscn`
- `add_node` (scenePath, nodeType, nodeName, parentNodePath?, properties?): adiciona nós
- `load_sprite` (scenePath, nodePath, texturePath): define a textura de um Sprite2D
- `save_scene`: salva ou cria uma variante
- `run_project` / `get_debug_output` / `stop_project`: rodar e ler erros
- `get_project_info`: confere a estrutura

O MCP não renomeia nós e não anexa scripts. Para isso, edite a `.tscn` diretamente (mudanças pequenas e textuais) ou use o editor.

## Arquitetura simples (obrigatório; ver Rules no CLAUDE.md)
- Uma cena por entidade real do jogo, e só quando ela for instanciada mais de uma vez ou tiver comportamento próprio. Senão, é nó dentro da cena existente.
- Raiz pelo papel físico/visual: `Node2D` (container), `CharacterBody2D` (movida por código com colisão), `Area2D` (detecção), `StaticBody2D` (obstáculo), `Control` (UI, só UI).
- Hierarquia rasa: no máximo ~3 níveis, a menos que haja motivo concreto.
- Um script por cena, em `scripts/<nome>.gd`, com tipagem estática. Comunicação via sinais do próprio nó ou chamada direta ao pai/filho conhecido.
- **Proibido sem mapeamento em `docs/roadmap.md`:** autoloads, EventBus, componentes genéricos, herança de cenas, state machine em nós, Resources de config.
- Nomes: arquivos em `snake_case` (`scenes/enemy.tscn`, `scripts/enemy.gd`), nós em `PascalCase`.

## Processo
1. Descreva a experiência mecânica que a cena serve (Rule 2) e a menor árvore de nós que a entrega.
2. `create_scene` → `add_node` para cada nó (colisões: `CollisionShape2D` com shape em `properties`).
3. Ajustes que o MCP não cobre: edite a `.tscn`.
4. Valide: `run_project` + `get_debug_output`, sem erros. Para scripts: `godot --headless --check-only --script <arquivo>`.
5. Informe ao usuário a árvore final em texto.

## Checklist
- [ ] Algum nó existe "por precaução"? Remova.
- [ ] Alguma abstração sem segundo uso real? Remova.
- [ ] A cena roda sem erros?
