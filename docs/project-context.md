# PixieDefense — Contexto do Projeto

Ver `roadmap.md` para a ordem de implementação por fases, `design-system.md` para o sistema visual e `balancing.md` para o framework de economia/dificuldade.

## Intenção
Tower defense 2D incremental em Godot 4.7 (GL Compatibility). O jogador é o último mago vivo, que fica mais forte consumindo a essência dos monstros que mata, defendendo o último refúgio da humanidade. Visual retro: sprites na paleta branca, recoloridos via shader em estilo VHS, com progressão de força/dificuldade comunicada por uma rampa de cor 8bit limitada.

## Identidade do jogo (pilares decididos)
1. **Mago único = torre fixa central**, dentro de uma única dungeon/caverna. Não existe mundo externo — a torre é a única porta de entrada para o esconderijo da humanidade.
2. **Combate ativo**: cada magia tem custo de mana e cooldown próprio; o jogador decide em tempo real quando e em qual corredor usar cada uma. Não é torre passiva clássica. Mira é **de área livre**: o jogador clica um ponto no espaço e a magia afeta um raio ali, podendo atingir mais de um corredor próximo numa única conjuração — isso recompensa posicionamento e timing de onda, não só "qual corredor escolher".
3. **Multi-lane radial**: múltiplos corredores convergem simultaneamente para a torre, dispostos ao redor dela (visão de cima, torre no centro). Todos os corredores ficam visíveis ao mesmo tempo, sem precisar mover câmera — essencial pro pilar de decidir entre ameaças simultâneas.
4. **Progressão incremental por save**: cada save é uma build contínua que se consolida fase a fase (dia a dia), não reseta entre dias (exceto por efeito do modo de dificuldade).
5. **Especialização em árvore**: três árvores — Defensiva, Destrutiva, Maldição. O jogador se especializa em uma (identidade principal), escolhida na criação do save e **fixa para todo o save** (sem respec), e ganha traços fixos das outras duas, destravados majoritariamente ao absorver essência de boss.
6. **Economia dupla**: essência (crescimento do mago, árvores) e dinheiro (defesas estruturais da base), com fontes e momentos de gasto diferentes — ver `balancing.md`.
7. **Leitura visual por cor**: tier de inimigo comunicado por rampa fixa de cor — ver `design-system.md`.
8. **Geração procedural diária**: o traçado do labirinto muda todo dia; regras estruturais (nº de lanes, pontos de estrangulamento) permanecem estáveis — ver `balancing.md`.
9. **Três modos de dificuldade** com consequência de falha diferente.

## Loop de uma sessão ("um dia")
1. Jogador desce à dungeon — a mesma estrutura geral, mas com corredores redesenhados.
2. Ondas de inimigos avançam pelos corredores; a cor do inimigo comunica o tier (branco→verde→azul→vermelho; roxo = mini-boss/boss).
3. A proporção de inimigos de tier alto cresce conforme os dias avançam dentro do save (gradiente, não unlock discreto).
4. Pontos fixos de "wave spike" dentro do dia trazem levas maiores/reforçadas — é onde mini-bosses e bosses aparecem.
5. O mago conjura magias ativas (mana + cooldown) da árvore especializada + traços cruzados, escolhendo corredor e timing.
6. Inimigos mortos dropam fragmentos de essência e dinheiro (drops independentes).
7. Fragmentos de essência se acumulam (10 = 1 essência) e são investidos durante a própria fase, nos nós da árvore. Abrir a interface de investimento **pausa o combate** — é uma decisão estratégica deliberada, não multitarefa em tempo real.
8. A base tem pontos de vida/defesa (pool próprio de cada dia — reseta a cada tentativa/dia, diferente de essência/dinheiro/árvore, que persistem entre dias no mesmo save); inimigos que atravessam descontam esses pontos. Fixtures (barricadas, guardas) comprados mitigam esse dano.
9. Fim do dia: dinheiro acumulado + bônus de conclusão de fase. Tela do comerciante etéreo (ainda dentro da mesma estrutura da torre, não é um local externo) para gastar dinheiro em defesas/fixtures.
10. Próximo dia começa com novo traçado de labirinto.

## Falha e modos de dificuldade
- **Fácil**: ao perder (pontos de defesa da base zeram), pode tentar a mesma fase de novo indefinidamente, sem perder progresso.
- **Normal**: ao perder, sofre penalidade (valor exato pendente — ver `balancing.md`) mas o save continua.
- **Homem de Aço** (permadeath): ao perder, o save é deletado permanentemente.

## Não-metas / anti-metas
- Não é multiplayer.
- Não há mundo externo à dungeon — nenhuma vila/overworld/tela separada fora da torre.
- Não é jogo de posicionamento de múltiplas torres (não é Bloons/Kingdom Rush clássico) — o mago é a única unidade ofensiva.
- A árvore de habilidade principal **não deve ser proceduralizada/randomizada em seus nós**. Achado da pesquisa de precedentes (`Talented`): árvores com nós aleatórios geram crítica consistente de ilegibilidade e de "RNG decide o jogo". A aleatoriedade neste projeto fica restrita à superfície (traçado do labirinto, qual boss aparece, variação de drop), nunca às regras estruturais.

## Decisões já tomadas (não renegociar sem motivo novo relevante)
- Nomenclatura: "fragmentos de essência" (micro-unidade) e "essência" (unidade cheia, 10 fragmentos).
- Cor por tier: branco (comum fraco) → verde → azul → vermelho (comum forte); roxo exclusivo de mini-boss/boss, com shader aprimorado.
- Árvores: Defensiva, Destrutiva, Maldição. Build = 1 especialista + traços fixos das outras 2, via essência de boss. Especialização é fixa no save, sem respec.
- Input de magia: mira de área livre (clique no espaço, raio de efeito, pode atingir mais de um corredor). Topologia: radial, torre no centro, corredores ao redor. Tela de árvore pausa o combate.
- Pontos de vida/defesa da base resetam por dia/tentativa (minha decisão — inferida de "retry sem perder progresso" no modo Fácil); essência, dinheiro e árvore persistem entre dias no mesmo save.
- Wave spikes disparam simultaneamente em todos os corredores, como um evento global do dia, não por lane independente (minha decisão — reforça o pilar de pressão multi-lane simultânea; frequência exata ainda pendente em `balancing.md`).
- Economia: essência (fragmentos, gasto em tempo real) é independente de dinheiro (drop de inimigo + conclusão de fase, gasto no comerciante etéreo entre dias).
- Fundo de cena: preto, levemente azulado. Estética geral: VHS (scanline/grain/aberração a calibrar). Shaders de game feel (glow, screen shake) reforçam impacto, não comunicam dificuldade — esse papel é exclusivo da cor.
- Assets base já disponíveis em `assets/`: `characters/Creatures.png` e `characters/People.png` (paleta branca, recoloridos por shader), tilesets `Civilized`/`Full`/`Natural`, e ícones de UI (poções, armas, joias, instrumentos, etc.) reaproveitáveis para HUD/loja/ícones de árvore.

## O que fica para o implementador decidir
- Algoritmo específico de geração procedural do labirinto, respeitando as regras estruturais fixadas em `balancing.md`.
- Arquitetura de código — seguindo as regras anti-over-engineering do `CLAUDE.md` do projeto (nada de managers/EventBus genéricos sem necessidade concreta e mapeada em `docs/roadmap.md`).
- Lista completa de magias por árvore (nomes, ícones, efeitos específicos).
- Tipos de inimigo além da cor (ex.: voador/terrestre, rápido/tanque) — não decidido; tratar como extensão futura se necessário, não assumir.
- Valores numéricos finais de balanceamento — `balancing.md` traz um framework inicial (hipóteses), não valores validados por playtesting.
