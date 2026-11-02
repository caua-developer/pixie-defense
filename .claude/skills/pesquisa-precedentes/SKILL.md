---
name: pesquisa-precedentes
description: Use antes de avaliar, propor ou opinar sobre uma mecânica de jogo (se é boa, ruim, divertida, frustrante) ou quando o usuário pedir referências/precedentes. Pesquisa jogos com a MESMA mecânica, ignorando tema narrativo e visual.
---

# Pesquisa de Precedentes Mecânicos

Objetivo: fundamentar decisões de design em jogos reais que usaram a mesma **mecânica**, nunca em tema parecido.

## Regra central
Selecione referências pela **mecânica**, total ou quase totalmente. Ignore narrativa, ambientação, estética, gênero de mercado e público.
- ✅ "Torres com alcance limitado que o jogador reposiciona durante a onda" → jogos com reposicionamento de defesas em tempo real, qualquer tema.
- ❌ "Jogo de fadas defendendo floresta" → jogos de fadas. Tema não é critério.

## Processo
1. **Decompor a mecânica** em verbos e regras: o que o jogador faz, que recurso gasta, que decisão toma, qual o feedback, qual o risco. Escreva em 1–3 frases sem nenhum substantivo temático.
2. **Buscar** (WebSearch) usando os termos mecânicos da decomposição — ex.: "tower defense reposition towers mid-wave", "lane defense limited placement slots" — mais termos de design (GDC talk, postmortem, game design analysis). Nunca pesquise pelo tema.
3. **Filtrar**: mantenha só jogos em que a mecânica é central ou quase idêntica. Descarte semelhança superficial. Mire em 3–6 referências.
4. **Para cada referência**, registre:
   - Jogo e como a mecânica funciona lá (diferenças em relação à nossa)
   - Recepção: o que jogadores/críticos/devs elogiaram ou criticaram *nessa mecânica* (reviews, postmortems, fóruns, patches que a alteraram)
   - Fonte (link)
5. **Sintetizar**: padrões que funcionaram, armadilhas recorrentes, variações e as condições em que cada uma deu certo.
6. **Ligar à experiência pretendida** (Rule 2 do CLAUDE.md): qual variação serve melhor à experiência que o usuário quer.

## Saída
```
Mecânica (decomposta): ...
Referências:
- <Jogo>: <como funciona> | Recepção: <...> | Fonte: <link>
Padrões: ...
Riscos conhecidos: ...
Recomendação para nossa experiência pretendida: ...
```

## Não fazer
- Opinar antes de ter referências.
- Contar como referência um jogo só porque tem o mesmo tema ou visual.
- Inventar recepção ou fontes. Se não achar evidência, diga que não achou.
