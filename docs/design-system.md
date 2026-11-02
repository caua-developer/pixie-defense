# PixieDefense — Design System Visual

Ver `project-context.md` para a visão geral do jogo. Este documento cobre só o sistema visual.

## Princípio geral
A paleta de cor **é** o sistema de comunicação de dificuldade — não decoração. Qualquer escolha visual nova deve responder: "isso reforça a leitura de tier, ou compete com ela?" Em caso de conflito, a leitura de tier vence.

## Paleta de tier de inimigos (fixa)

| Tier | Cor | Uso |
|---|---|---|
| 0 | Branco (cor nativa do sprite) | inimigo comum, mais fraco |
| 1 | Verde | comum, um nível acima |
| 2 | Azul | comum, um nível acima |
| 3 | Vermelho | comum, tier mais forte |
| Especial | Roxo | mini-boss e boss, cor exclusiva — nunca usada em comum |

- A cor é aplicada via **shader de tint** sobre os sprites brancos originais (`Creatures.png`) — nunca editando o asset-fonte.
- Variação dentro de um tier é permitida (jitter leve de matiz/brilho, pra dar sensação de aleatoriedade/variedade por save), mas deve ficar contida o suficiente para não ambiguar com o tier vizinho (um "verde" não pode derivar perto o bastante do azul).
- Essa paleta é uma extensão do vocabulário de raridade de item de ARPGs (Diablo/WoW) aplicada a inimigo comum — não achamos precedente direto testado (ver pesquisa de precedentes), então calibrar visualmente antes de travar os valores exatos de matiz.

## Shader de boss / mini-boss
Base roxa + camada adicional de destaque, pra ser inconfundível à distância mesmo em tela pequena. Candidatos a prototipar (não travado):
- Glow pulsante mais forte que o padrão.
- Aberração cromática/distorção adicional, coerente com a estética VHS geral.
- Contorno ou halo.

## Estética VHS
- **Fundo de cena**: preto, levemente azulado — nunca preto puro.
- **Pós-processamento geral**: leve scanline/grain condizente com VHS. Intensidade exata a calibrar em protótipo (sem precedente direto pesquisado — tratar como hipótese visual, não valor travado).
- **Shaders de game feel** (separados do shader de tier de cor): glow em hit/impacto, screen shake em dano à base ou acerto crítico, e outros efeitos de feedback. Função: reforçar sensação de impacto — nunca comunicar dificuldade (isso é papel exclusivo da cor de tier).

## Composição de cena (topologia radial)
A torre fica no centro da tela, com os corredores saindo em várias direções ao redor dela, em visão de cima. Todos os corredores devem ficar visíveis simultaneamente sem scroll de câmera — é o que sustenta a decisão de onde mirar a magia de área sob pressão de múltiplas ameaças ao mesmo tempo. Implicações pro uso dos tilesets: o chão/caminho precisa funcionar visualmente em qualquer orientação ao redor do centro (não só horizontal/vertical como um TD lateral clássico).

## Uso dos assets existentes (`assets/`)
- `characters/Creatures.png`: base de sprite de monstros, recolorida por tier via shader.
- `characters/People.png`: mago e humanos (aliados, NPCs da base).
- `tilesets/Civilized-no-bg.png`, `Full-no-bg.png`, `Natural-no-bg.png`: ambientação da dungeon/caverna — qual conjunto compõe o visual final ainda não foi decidido, escolher conforme a direção de arte da caverna/refúgio.
- `ui/*.png` (Clothing, Food, Gems-Jewels-and-Money, Instruments, Jewelry, Misc, Misc-Future, Potions, Tools, UI, Weapons): ícones reaproveitáveis para HUD, loja do comerciante etéreo e ícones de nó de árvore de habilidade — preferir reaproveitar um ícone existente ao criar um novo quando o tema servir.

## O que fica para prototipagem (não travar agora)
- Intensidade exata de cada efeito VHS (grain, scanline, aberração).
- Faixa de hue jitter dentro de cada tier.
- Composição final da paleta de UI/HUD (ainda não decidida).
- Efeito visual exato do shader de boss/mini-boss.
