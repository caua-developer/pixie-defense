# PixieDefense — Framework de Balanceamento (v0)

> Este documento é um **framework inicial**, não valores validados por playtesting. Pendências explícitas estão marcadas como tal — não travar número sem calibrar em jogo.

Ver `project-context.md` para a visão geral do jogo.

## Princípio (da pesquisa de precedentes)
Regras estruturais fixas e legíveis; aleatoriedade só na superfície. A matemática abaixo deve ser clara e consistente entre dias — a variação vem do traçado do labirinto e de qual boss aparece, nunca da fórmula em si. (Achado da pesquisa: ilegibilidade/aleatoriedade sem regras estáveis foi a crítica mais recorrente entre os precedentes pesquisados — Talented, Dungeon Warfare, Spelunky Daily.)

## Economia de essência
- **Fragmento de essência**: menor unidade, dropado por inimigo morto.
- **Conversão**: 10 fragmentos = 1 essência.
- **Drop por tier** (ponto de partida, a calibrar em playtesting):
  | Fonte | Drop |
  |---|---|
  | Branco | 1 fragmento |
  | Verde | hipótese: 2 fragmentos |
  | Azul | hipótese: 4 fragmentos |
  | Vermelho | hipótese: 6–8 fragmentos |
  | Mini-boss | meia-essência (= 5 fragmentos equivalentes) |
  | Boss | 1 essência cheia (= 10 fragmentos equivalentes) |
- Essência é gasta **em tempo real**, durante a própria fase, nos nós da árvore especializada (como uma barra de XP que enche e é investida).
- Traços cruzados das outras 2 árvores são destravados **majoritariamente por essência de boss** — gatilho raro e pontual, não por acumulação linear de fragmentos comuns. Manter sempre claro pro jogador quando/por que esse traço foi destravado, para não repetir a crítica de "RNG decide o jogo" encontrada na pesquisa.

## Economia de dinheiro
- **Fonte 1**: drop de inimigo morto (moeda independente do drop de essência — cai junto, mas é outro recurso).
- **Fonte 2**: bônus de conclusão de fase/dia.
- **Gasto**: comerciante etéreo, na transição entre dias, em defesas estruturais da base (barricadas, guardas, fixtures).
- Valores de drop e custo de fixture: **pendente**, depende de testar o ritmo de aquisição.

## Progressão de dificuldade dentro do save
- A proporção de inimigos de tier alto cresce com os dias — é um **gradiente**, não um unlock discreto.
- Ponto de partida hipotético (calibrar):
  - Dias iniciais: majoritariamente branco, traço de verde.
  - Dias intermediários: mistura branco/verde/azul.
  - Dias avançados: azul/vermelho dominante, brancos residuais.
- Dentro de cada dia, pontos fixos de **wave spike**: leva maior com inimigos de tier reforçado. Mini-bosses e bosses aparecem especificamente nesses pontos.
- Wave spike é um **evento global do dia** — dispara simultaneamente em todos os corredores (não é um spawner independente por lane). Reforça o pilar de pressão multi-lane simultânea.
- Frequência do wave spike: hipótese de partida — 1 wave spike a cada N ondas regulares. N pendente de calibração.

## Estrutura do labirinto (regras estáveis — não aleatorizar)
- **Nº de lanes simultâneas**: fixo por "marco de progressão" do save (ex.: dias 1–X usam N lanes, aumenta em marcos definidos). Não varia aleatoriamente dia a dia — só o traçado dentro das lanes varia.
- **Pontos de estrangulamento** perto da torre: devem existir de forma consistente entre dias, para que o jogador aprenda o *padrão* de geração (não o mapa exato).
- O que varia livremente a cada dia: o traçado específico dos corredores dentro dessas regras fixas.

## Vida da base
Os pontos de vida/defesa da base são um pool **por dia/tentativa** — resetam no início de cada dia (incluindo em retries no modo Fácil). Essência, dinheiro e progresso de árvore persistem entre dias no mesmo save; vida da base não.

## Modos de dificuldade — consequência de falha
- **Fácil**: falha = retry imediato da mesma fase, sem perda.
- **Normal**: falha = penalidade (pendente — hipóteses a testar: perda parcial do dinheiro acumulado não gasto, ou retrocesso de 1 dia na curva de dificuldade de inimigos) + save continua.
- **Homem de Aço**: falha = save deletado permanentemente.

## Pendências explícitas (não travar sem playtesting)
- Valores exatos de drop de fragmento por tier.
- Custo de cada nó das 3 árvores (Defensiva/Destrutiva/Maldição).
- Frequência e intensidade dos wave spikes (valor de N).
- Penalidade exata do modo Normal.
- Nº de lanes por marco de progressão e em que dia cada marco acontece.
- Custo das fixtures de defesa da base (barricadas, guardas).
