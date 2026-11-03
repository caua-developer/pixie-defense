# Fase 4 — As 3 árvores + especialização + traço cruzado de boss (Design)

> Documento de design da Fase 4 do `docs/roadmap.md`. Produzido via `superpowers:brainstorming`. Depois de aprovado, o próximo passo é `superpowers:writing-plans` (um plano por fase, como já feito nas Fases 0–3).

## Intenção e porquê

A Fase 3 validou o loop de essência + 1 árvore (Destrutiva). A Fase 4 completa o sistema de build: qualquer uma das 3 árvores (Destrutiva, Defensiva, Maldição) pode ser a especialização principal do save, escolhida uma única vez e fixa (sem respec — decisão já registrada em `project-context.md`, pilar 5). As outras 2 árvores não especializadas não desaparecem: cada uma contribui **um afixo fixo** que se anexa à habilidade principal da árvore escolhida, destravado ao absorver essência de boss. Isso exige introduzir uma fonte de essência de boss (mini-boss/boss, tier roxo) nesta fase, mesmo que o sistema formal de wave spike só chegue na Fase 7.

## Goals

- Qualquer uma das 3 árvores pode ser escolhida como especialização principal do save, com os mesmos 4 nós compráveis via essência (mesma UI/padrão da Fase 3).
- As 2 árvores não escolhidas contribuem, juntas, exatamente 2 afixos fixos (um cada) que modificam a habilidade principal da árvore escolhida — nunca dão acesso à magia/nós completos da árvore não escolhida.
- Existe uma fonte de essência de boss nesta fase (mini-boss = meia-essência, boss = essência cheia — já fixado em `balancing.md`), com um gatilho de spawn simples e determinístico.
- A escolha de especialização acontece uma vez, no início, e fica persistida (ver "Save mínimo" abaixo).

## Non-goals (fora do escopo desta fase)

- Economia de dinheiro, comerciante etéreo (Fase 5).
- Geração procedural do labirinto (Fase 6).
- Progressão de dificuldade entre dias e sistema formal de wave spike (Fase 7) — o gatilho de boss desta fase é um substituto simplificado, não a implementação final.
- Modos de dificuldade (Fase 8).
- Qualquer conteúdo de save alem de `specialization_tree` (dinheiro, dia atual, vida da base entre dias, etc. entram quando as fases correspondentes pedirem).
- Respec de especialização.
- Conjunto completo de afixos cruzados para todas as combinações futuras além das 6 descritas aqui (já é o conjunto completo do triângulo 3×2 — não há mais a adicionar nesta fase).

## Anti-goals

- O golem da Defensiva **nunca ataca por iniciativa própria** (não busca, não persegue). Ele só bloqueia a passagem e absorve dano até morrer. Isso preserva o anti-meta já registrado em `project-context.md`: "o mago é a única unidade ofensiva". O afixo "espinhos"/retaliação foi avaliado e descartado nesta sessão por quebrar esse anti-meta sem necessidade — a fonte de progressão de dano da Defensiva é indireta (nó "Fúria do Guardião", abaixo), não uma segunda unidade atacante.
- Nenhum valor numérico desta fase é definitivo — todos os custos/magnitudes são hipótese, a calibrar na Fase 10 (mesma convenção já usada nas Fases 1–3).
- Nenhuma abstração de "nó de árvore genérico"/Resource/manager deve ser introduzida só por estarem "prontas para o futuro" — a única abstração nova justificada aqui é a generalização de `skill_tree_panel.gd` para suportar 3 árvores (porque agora há um segundo e terceiro consumidor real do mesmo formato, não especulação — ver nota já deixada no plano da Fase 3).

## Decisões já tomadas nesta sessão (não renegociar sem motivo novo)

### As 3 árvores

| Árvore | Habilidade principal (mesma mira de área livre já existente) | Efeito | 4 nós (compráveis só por quem especializa) |
|---|---|---|---|
| Destrutiva (já existe, Fase 3) | Magia de dano direto | Dano de área no raio clicado | Dano+, Cooldown-, Custo de Mana-, Raio+ |
| Defensiva (nova) | Invocar golem no ponto clicado (dentro de um corredor) | Golem physical blocker: HP próprio, bloqueia a passagem de inimigos naquele corredor e absorve seus ataques até morrer; nunca ataca | Golem HP+, Golem Cooldown- (reduz o cooldown geral de conjurar a habilidade — na implementação, recast enquanto um golem já está vivo simplesmente substitui o golem atual, não espera a morte dele; mais simples e consistente com o cooldown genérico das outras 2 árvores), Golem Custo de Mana-, **Fúria do Guardião** (a magia base do mago recebe +dano enquanto houver um golem vivo em qualquer corredor) |
| Maldição (nova) | Magia de debuff no raio clicado | Inimigos atingidos recebem +X% de dano de qualquer fonte, por uma duração (em vez de dano direto) | Potência+ (aumenta o %), Duração+, Cooldown-, Custo de Mana- |

- Quem **não** especializa numa árvore não tem acesso à magia/nós dela. Se a árvore não especializada for a Destrutiva, o jogador ainda mantém a magia de dano base do mago (existente desde a Fase 1) em nível fixo, sem upgrade — ela nunca é removida do jogo, só para de ser upável se você não a escolher como especialização.
- **Input de 2 habilidades (decisão do usuário nesta sessão, após revisão do builder-check):** quem especializa em Defensiva ou Maldição passa a ter 2 habilidades conjuráveis simultaneamente — a magia base do mago (fixa) e a habilidade nova da árvore escolhida (golem ou maldição, upável). Cada uma usa um input separado (clique esquerdo = magia base, clique direito = habilidade da árvore) com **mana e cooldown independentes entre si** — não compartilham pool. Quem especializa em Destrutiva continua com 1 input só (a mesma magia base, agora upável), já que não há uma segunda habilidade nova pra ela nesta fase.
- **Mira do golem (minha decisão como designer, resolvendo ambiguidade apontada no builder-check):** usa a mesma mira de área livre das outras magias, sem validação especial de alvo — o clique sempre gasta mana/cooldown normalmente, e o golem nasce no ponto do corredor mais próximo do clique (snap automático ao caminho), mantendo o input consistente entre as 3 árvores (nenhuma delas tem conceito de "clique inválido").
- **Composição do debuff de dano da Maldição (minha decisão como designer, resolvendo ambiguidade apontada no builder-check):** um campo direto `damage_taken_multiplier: float = 1.0` em `enemy.gd`, aplicado dentro de `take_damage()` (ex.: `hp -= amount * damage_taken_multiplier`), setado ao receber a maldição e resetado quando a duração acaba. Sem sistema genérico de status effect/buff — mesma convenção de var direta já usada em `mago.gd`/`enemy.gd` nas fases anteriores. Nesta fase não há necessidade de regra de stacking (não há 2 fontes do mesmo debuff simultâneas previstas).
- "Fúria do Guardião" foi a solução encontrada nesta sessão para a Defensiva não ficar "chata"/sem progressão de dano: a fonte de dano continua sendo só a magia do mago (nunca o golem), mas a árvore Defensiva dá um jeito de amplificá-la condicionada a manter um golem vivo — mantém o anti-meta intacto e ainda dá uma curva de poder pra quem especializa em Defensiva.

### Afixos cruzados (triângulo completo — 6 afixos fixos, cada árvore tem exatamente 1 "assinatura" que leva pra qualquer árvore principal)

"Assinatura" de cada árvore quando ela **não** é a principal: Destrutiva = dano instantâneo de fogo; Defensiva = lentidão/controle; Maldição = dano contínuo ao longo do tempo.

| Árvore principal | Afixo vindo da Destrutiva | Afixo vindo da Defensiva | Afixo vindo da Maldição |
|---|---|---|---|
| Destrutiva | (é a principal) | A magia de dano também aplica lentidão no inimigo atingido | A magia de dano também aplica dano contínuo (DoT) no inimigo atingido |
| Defensiva | Inimigos que atacam o golem sofrem dano de fogo | (é a principal) | Inimigos que atacam o golem também sofrem dano contínuo (DoT) |
| Maldição | Ao aplicar a maldição, causa um estouro instantâneo de dano de fogo | A maldição também aplica lentidão no inimigo | (é a principal) |

- Cada especialização usa só os 2 afixos das árvores que ela não escolheu (a linha da tabela correspondente à árvore principal escolhida).
- **Destravamento:** existe um contador de "essência de boss" (não se mistura com a essência normal/fragmentos da Fase 3). Mini-boss morto soma 0.5 ponto, boss morto soma 1 ponto. Ao atingir **1 ponto**, destrava o primeiro afixo da linha (ordem fixa: segue a ordem das colunas da tabela acima, pulando a coluna da árvore principal); ao atingir **2 pontos**, destrava o segundo. Acima de 2 pontos não há mais nada a destravar nesta fase (hipótese simples — sem fila de upgrades repetíveis aqui).
- Os afixos não são comprados — são só exibidos no painel da árvore como "destravado"/"bloqueado (precisa de X essência de boss)", sem custo em essência normal.

### Mini-boss / boss (tier roxo)

- Reaproveita o inimigo existente (`enemy.gd`), com **2 índices de tier adicionais, ambos roxos** (decisão do usuário nesta sessão, após revisão do builder-check): índice 4 = mini-boss (HP/dano moderadamente maior que o tier vermelho) e índice 5 = boss (HP/dano bem maior que o mini-boss) — seguindo o mesmo padrão de escala já usado entre os tiers comuns (`TIER_HP_MULT`), não valores idênticos. Boss ganha um reforço extra no shader (glow mais intenso) além do tint roxo compartilhado com o mini-boss, pra ficar visualmente distinguível mesmo sendo a mesma cor base.
- **Gatilho de spawn (substituto simplificado do wave spike formal da Fase 7):** contagem global de inimigos mortos. A cada 20 mortes, spawna 1 mini-boss (tier 4); a cada 50 mortes, spawna 1 boss (tier 5) (valores hipótese, a calibrar na Fase 10). Mini-boss e boss usam o spawn de corredor já existente (sem lógica nova de posicionamento).
- Visual: reaproveita o shader de tint existente com a cor roxa + um glow pulsante mais forte sobre ele (candidato já sugerido em `design-system.md`, seção "Shader de boss/mini-boss" — não travado, prototipar intensidade; boss recebe um glow ainda mais forte que o mini-boss, ver acima).
- Ao morrer, soma ao contador de essência de boss (acima) em vez do fragmento normal de essência.

### Escolha de especialização + save mínimo

- Uma tela/painel aparece ao abrir a cena principal (antes do jogo começar a rodar, pausa o jogo), com 3 opções (Destrutiva/Defensiva/Maldição). Escolha única, sem respec — confirmação explícita antes de travar (ex.: segundo clique/botão "Confirmar"), já que é irreversível no save.
- Um novo `scripts/save_manager.gd` grava a escolha em `user://save.json`, com um único campo por agora: `specialization_tree`. Ao abrir o jogo, se o arquivo já existir e tiver esse campo, pula a tela de escolha e carrega a árvore salva direto.
- **Nota de justificativa da Regra 1 do `CLAUDE.md`** (exceção documentada): esta infraestrutura de save, mínima como é, antecipa necessidade concreta e já mapeada em fases futuras — Fase 5 (dinheiro e progresso persistente entre dias) e Fase 8 (modo Homem de Aço precisa deletar um save real). Não é especulação; é o primeiro passo de algo que o roadmap já exige adiante. Mantém-se mínima: nenhum outro campo de save é criado nesta fase além de `specialization_tree`.

## O que fica para o plano/implementador decidir

- Arquitetura exata de como o golem bloqueia fisicamente a passagem no corredor e como o inimigo reage (pausa movimento + ataca o golem vs. outra abordagem) — consultar skill `godot-prompter:physics-system` e/ou `ai-navigation` antes de decidir o nó/colisão, respeitando a Regra 1 (sem pathfinding novo, corredores ainda são fixos nesta fase).
- Valores numéricos exatos: HP/dano do mini-boss e boss, magnitude de cada nó novo (Defensiva/Maldição), magnitude de cada um dos 6 afixos, UI exata do painel de escolha de especialização e do contador de essência de boss na HUD.
- Generalização do `skill_tree_panel.gd` da Fase 3 (hoje hardcoded pra 4 nós da Destrutiva) para funcionar com a árvore que foi escolhida como principal + exibir os 2 afixos da linha correspondente.
- Nome/ícone de cada nó e afixo (reaproveitar ícones de `assets/ui/*` conforme já orientado em `design-system.md`).
- Testes de sintaxe/verificação manual seguem o mesmo padrão das Fases 1–3 (sem framework de teste automatizado, igual já decidido nas fases anteriores).

## Referências

- `docs/roadmap.md` — Fase 4.
- `docs/project-context.md` — pilares 5 (árvores/especialização) e 6 (economia dupla), anti-metas.
- `docs/balancing.md` — economia de essência (drop de mini-boss/boss já fixado).
- `docs/design-system.md` — paleta de tier, shader de boss/mini-boss.
- `docs/superpowers/plans/2026-11-02-fase3-essencia-arvore-destrutiva.md` — padrão de UI/arquitetura da árvore já implementada, ponto de partida pra generalizar.
