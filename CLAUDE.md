# PixieDefense

Jogo 2D em Godot 4.7 (GL Compatibility), GDScript. Cena principal: `res://scenes/main.tscn`.

- Godot: `C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`
- MCP `godot` (configurado em `.mcp.json`) → build local de `C:/Users/Cauã/Documents/godot-mcp`
- Estrutura: `scenes/` (.tscn), `scripts/` (.gd), `assets/` (arte, áudio, fontes)

## Rules

### 1. Anti-Over-Engineering e Anti-Abstração Desnecessária
- Implemente o mínimo que entrega a mecânica pedida **agora**. Nada de autoloads, EventBus, managers, componentes genéricos, classes base, state machines em nós ou Resources de configuração "para o futuro".
- Prefira um script direto num nó a uma camada de abstração. Duplicação pequena é aceitável até existir o terceiro caso real.
- **Exceção:** um sistema complexo só entra se houver mapeamento explícito para uma fase futura — registre no `docs/roadmap.md` qual fase/feature concreta exige aquilo e por quê. Sem esse registro, não implemente.
- Skills externas (ex.: `godot-prompter:*`) que recomendem estruturas maiores servem de referência de *como* fazer, não de licença para fazer mais. Esta regra tem precedência.

### 2. Interpretar pela experiência mecânica pretendida
- Antes de implementar, identifique a **experiência** que o pedido quer criar (sensação, decisão do jogador, ritmo, tensão), não só a descrição literal.
- Se a leitura literal e a experiência pretendida divergirem, siga a experiência e diga explicitamente qual interpretação usou. Se a ambiguidade mudar o resultado de forma relevante, pergunte.
- Exemplo: "inimigos mais rápidos" pode significar "mais pressão no jogador" — talvez o melhor seja spawn mais denso, não só `speed` maior.

### 3. Não julgar mecânicas sem precedentes
- Não afirme que uma mecânica é boa, ruim, frustrante ou divertida com base em intuição.
- Antes de opinar, use a skill `pesquisa-precedentes` e cite jogos que usaram a mecânica (ou similar) e como ela foi recebida.
- Sem pesquisa, limite-se a descrever trade-offs como hipóteses, marcadas como tal.

## Skills do projeto
- `pesquisa-precedentes` — pesquisa de referências focada na mecânica (ignora tema narrativo/visual).
- `criacao-projeto-2d` — criação de cenas e nós 2D via MCP mantendo arquitetura simples.
