# PixieDefense — Roadmap de Implementação

Mapa de fases do início ao fim do desenvolvimento. Cada fase tem um objetivo validável e uma lista explícita do que fica fora dela (regra anti-over-engineering do `CLAUDE.md`: nada de sistema genérico/abstrato antes da fase que realmente precisa dele).

Este documento também serve como o registro de exceção exigido pela Regra 1 do `CLAUDE.md`: todo sistema complexo citado abaixo (geração procedural, árvore de habilidade, economia dupla, etc.) está aqui porque é pedido explícito do design em `project-context.md`/`balancing.md`/`design-system.md`, não uma abstração especulativa — a fase indicada é a justificativa.

Cada fase, quando for implementada, ganha seu próprio plano via `superpowers:writing-plans` (um plano por fase, não um plano único pra tudo). Este roadmap não substitui esses planos — ele só define a ordem e o escopo mínimo de cada um.

Estado atual do projeto: Fase 1 concluída (1 corredor fixo, 1 inimigo tier branco com spawn por timer, 1 magia com mana/cooldown e mira de área livre, pool de vida da base com fim de fase ao zerar — ver `docs/superpowers/plans/2026-11-02-fase1-vertical-slice-combate.md`). Próxima fase: Fase 2.

## Fase 0 — Fundação da cena
**Objetivo:** cena principal carrega, mago estático no centro, câmera fixa em vista de cima.
- Nó do mago (torre) parado no centro de `main.tscn`.
- Câmera e resolução configuradas para visão radial (ver `design-system.md`).
- Sem combate, sem inimigos, sem UI ainda.

## Fase 1 — Vertical slice de combate ativo (1 corredor, 1 magia)
**Objetivo:** validar a sensação do combate ativo (mira de área livre + mana/cooldown) antes de qualquer outro sistema — é a decisão de maior risco do design (ver `project-context.md`).
- 1 corredor fixo (hardcoded, sem geração procedural).
- 1 tipo de inimigo (tier branco), spawn simples por timer.
- 1 magia com mana + cooldown, mira de área livre (clique no espaço, raio de efeito).
- Base com pool de vida que desconta por inimigo que chega; perder = fim da fase (ainda sem modos de dificuldade).
- **Fora do escopo desta fase:** multi-lane, árvores de habilidade, essência/dinheiro, geração procedural, VHS shader, mini-boss/boss.

## Fase 2 — Multi-lane radial + tier de cor
**Objetivo:** validar a pressão de decidir entre corredores simultâneos — o segundo pilar de maior risco.
- Expandir de 1 corredor fixo para N corredores fixos em disposição radial ao redor da torre.
- Tier de inimigo por cor (branco→verde→azul→vermelho) via shader de tint sobre o sprite branco (`design-system.md`), ainda com proporção de tiers fixa manualmente (sem progressão por dia ainda).
- Mira de área livre precisa continuar funcionando ao atingir mais de um corredor por conjuração.
- **Fora do escopo:** geração procedural dos corredores (continuam fixos, só a quantidade/disposição muda), economia, árvores.

## Fase 3 — Essência + árvore de habilidade (1 árvore primeiro)
**Objetivo:** validar o loop de investir essência em tempo real com a UI pausando o combate (`project-context.md`).
- Fragmentos de essência dropam dos inimigos (conversão 10:1 de `balancing.md`).
- UI de árvore (pausa o jogo ao abrir) com nós de 1 árvore só (ex.: Destrutiva) pra validar o fluxo de investimento.
- Especialização ainda não precisa ser escolhida na criação de save nesta fase — isso entra quando as 3 árvores existirem.
- **Fora do escopo:** as outras 2 árvores, traços cruzados via essência de boss, boss em si.

## Fase 4 — As 3 árvores + especialização fixa + traço cruzado de boss
**Objetivo:** completar o sistema de build.
- Árvores Defensiva e Maldição implementadas com a mesma UI da Fase 3.
- Escolha de especialização na criação do save, fixa (sem respec) — ver decisão em `project-context.md`.
- Introduzir mini-boss/boss (tier roxo, shader aprimorado) como fonte de essência de boss.
- Traços cruzados fixos das outras 2 árvores, destravados ao absorver essência de boss.
- **Fora do escopo:** economia de dinheiro, comerciante etéreo, geração procedural, modos de dificuldade.

## Fase 5 — Economia de dinheiro + comerciante etéreo + defesas da base
**Objetivo:** completar a segunda economia e o loop entre dias.
- Dinheiro dropado por inimigo (independente da essência) + bônus de conclusão de fase.
- Tela do comerciante etéreo na transição entre dias (dentro da mesma estrutura, não é hub externo).
- Fixtures de defesa da base (barricadas, guardas) compráveis, mitigando dano à vida da base.
- Vida da base confirmada como pool por dia/tentativa (reseta a cada dia — ver `balancing.md`).
- **Fora do escopo:** geração procedural, modos de dificuldade, wave spikes.

## Fase 6 — Geração procedural diária do labirinto
**Objetivo:** substituir os corredores fixos da Fase 2 por geração procedural, respeitando regras estruturais estáveis (`balancing.md`): nº de lanes fixo por marco de progressão, pontos de estrangulamento consistentes, só o traçado varia.
- Gerador roda uma vez por dia, produz N corredores conforme o marco de progressão do save.
- Validar que o gerador nunca produz corredor inalcançável ou sem gargalo perto da torre.
- **Fora do escopo:** variar o nº de lanes dentro do mesmo dia, variar regras estruturais por save.

## Fase 7 — Progressão de dificuldade entre dias + wave spikes
**Objetivo:** fazer o jogo ficar mais difícil ao longo do save, conforme o gradiente de `balancing.md`.
- Proporção de tiers de inimigo migrando gradualmente conforme os dias avançam.
- Wave spike como evento global simultâneo em todos os corredores (ver decisão em `balancing.md`), com frequência inicial hipotética a calibrar.
- Mini-bosses/bosses aparecendo especificamente nos wave spikes.

## Fase 8 — Modos de dificuldade (Fácil / Normal / Homem de Aço)
**Objetivo:** implementar a consequência de falha por modo (`project-context.md`).
- Fácil: retry imediato da mesma fase sem perda.
- Normal: penalidade ao falhar (valor a definir), save continua.
- Homem de Aço: falha deleta o save permanentemente — cuidado especial aqui com confirmação de UI antes de um delete irreversível.

## Fase 9 — Polimento visual VHS + game feel
**Objetivo:** aplicar a camada estética sobre um jogo já funcional, pra calibrar intensidade com o jogo rodando de verdade, não no vácuo.
- Fundo preto/levemente azulado, scanline/grain, aberração cromática (intensidade calibrada em protótipo, `design-system.md`).
- Shaders de game feel: glow em hit, screen shake em dano à base/crítico.
- Shader aprimorado específico de boss/mini-boss.

## Fase 10 — Calibração de balanceamento
**Objetivo:** fechar os valores numéricos deixados como hipótese em `balancing.md` (drops por tier, custo de nó, frequência de wave spike, penalidade do modo Normal, custo de fixture) via playtesting, agora que todos os sistemas existem.

## Como usar este roadmap
Ao iniciar uma fase, invoque `superpowers:writing-plans` com o objetivo e o "fora do escopo" dessa fase específica — o plano detalha os passos de implementação (nós, scripts, cenas) dentro desse recorte. Não pule fases: cada uma valida uma decisão de risco antes da próxima depender dela.
