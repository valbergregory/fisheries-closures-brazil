# Relatório de viabilidade — primeira entrega (2026-09-03)

## 1. Matriz de seleção do tratamento regulatório

Notas 0–3 (3 = melhor). Candidatas avaliadas com base em fontes REALMENTE
verificadas hoje (nenhuma nota presume disponibilidade não testada).

| Critério | (A) MONA/APA Trindade (Dec. 9.312/2018) | (B) Defeso camarão SE/S — calendário 2023 (Port. 656/2022) | (C) Defeso lagosta N/NE (Port. 221/2021) | (D) Defeso sardinha SE/S (IN 15/2009) | (E) Seguro-Defeso (tempestividade) | (F) Fiscalização (autos ICMBio) |
|---|---|---|---|---|---|---|
| Data identificável | 3 | 3 | 2 | 1 (regime antigo, recorrente) | 2 (mensal) | 1 |
| Polígono/área | 3 (WFS recuperado) | 2 (MT+ZEE a resolver, D3) | 2 | 2 | 1 (municipal) | 2 |
| Grupo tratado claro | 3 | 3 (arrasto) | 2 | 2 | 3 | 1 |
| Duração/frequência | 3 (permanente) | 3 (anual, com quebra) | 2 | 2 | 3 | 1 |
| Controle plausível | 2 (SDID/montes) | 3 (mesma célula, entre anos) | 2 | 1 | 2 | 1 |
| Dados pré | 3 (AIS 2016+) | 3 | 2 | 2 | 2 (série a confirmar) | 2 |
| Dados pós | 3 | 3 | 3 | 3 | 3 | 3 |
| Spillovers mensuráveis | 3 (anéis oceânicos) | 3 (temporal + espacial) | 2 | 2 | 1 | 1 |
| Compatibilidade AIS | 3 (frota industrial offshore) | 2 (arrasto costeiro parcial) | 1 (artesanal!) | 2 (traineiras) | 1 (artesanal!) | 2 |
| Relevância econômica | 2 | 3 (maior pescaria de crustáceo S/SE) | 3 | 3 | 3 | 2 |
| Documentação jurídica | 3 (decreto recuperado) | 3 (íntegra recuperada) | 2 (PDF localizado) | 2 | 2 (Lei 10.779) | 1 |
| Risco de endogeneidade | 2 (local escolhido por valor ecológico) | 2 (calendário negociado c/ setor) | 2 | 2 | 2 (atraso não aleatório) | 3 (reversa) |
| Viabilidade individual | 3 | 3 | 1 | 2 | 2 | 1 |
| **Total** | **36** | **36** | **26** | **26** | **27** | **21** |

**Decisão proposta (D1):** desenho principal **(A)** — evento espacial nítido,
melhor compatibilidade AIS e polígonos já recuperados; desenho secundário
**(B)** — única candidata com variação temporal REAL de calendário (identifica
contra sazonalidade). (E) e (F) entram como mecanismos/heterogeneidade, não
como desenho principal. (C) descartada como principal por incompatibilidade
AIS (frota lagosteira majoritariamente artesanal).

## 2. Resultados do teste mínimo (checklist do brief, seção 17)

| # | Exigência | Resultado |
|---|---|---|
| 1 | Norma oficial recuperada | **SIM** — Portaria SAP/MAPA 656/2022 (PDF IBAMA 864 KB + DOU HTML) e Decreto 9.312/2018 (Planalto) |
| 2 | Texto e metadados preservados | **SIM** — `data/legal/` + `.txt` extraído + SHA-256 em `data/metadata/checksums_legal.txt` |
| 3 | Regra estruturada | **SIM** — `outputs/policies/PORT_SAP_MAPA_656_2022_r1.json`, esquema válido; **validação humana pendente** (4 open_issues, ver D8) |
| 4 | Polígono válido | **SIM** — MONA (4 anéis, 27 vértices) e APA (1 anel, 1.323 vértices) via WFS INDE; anéis fechados, coordenadas em faixa |
| 5 | Período válido | **SIM** — datas do decreto e do defeso extraídas do texto oficial (com transição 2022 documentada) |
| 6 | Cruzamento com esforço | **PARCIAL** — mecânica de cruzamento demonstrada (célula×zona×mês); coluna de esforço = NA até GFW_TOKEN (bloqueio administrativo) |
| 7 | Variação suficiente | **SIM (espacial)** — 91 células MONA, 561 APA, 1.416 controle; variação temporal de esforço aguarda GFW |
| 8 | Buffer interno/externo | **SIM** — distância à fronteira da APA computada por célula (proxy equiretangular; sf na fase 1) |
| 9 | Estatísticas antes/depois | **ADIADO** — depende do item 6 (sem esforço real, qualquer estatística seria sintética — proibido) |
| 10 | Mapa preliminar | **SIM** — `outputs/diagnostics/map_trindade_pilot.png` |
| 11 | Modelo diagnóstico | **ADIADO** — mesmo motivo do item 9; especificação já escrita (E1 em estimand_table.md) |

Painel piloto: 124.080 linhas (2.068 células × 60 meses, 2016–2020), com
`post`, `treated_mona`, `treated_apa`, `dist_boundary_km` — pronto para
receber o raster GFW.

## 3. Ambiente

| Ferramenta | Versão | Status |
|---|---|---|
| R | 4.4.3 (ucrt); 4.4.2 também presente | fora do PATH do shell — usar caminho completo ou RStudio |
| Python | 3.13.2 | no PATH |
| Quarto | 1.9.38 | OK |
| Git | 2.49.0.windows.1 | OK |
| DuckDB CLI | ausente | usar pacote R `duckdb` (fase 1, via renv) |
| uv | ausente | instalar se a camada Python crescer |
| R pacotes presentes | targets, renv, data.table, fixest, did, modelsummary, tidyverse, testthat, quarto, httr2… | **ausentes: sf, terra, duckdb, arrow, rdrobust, synthdid, sfdep/spdep** → `renv::init()` + instalação na fase 1 |
| Python pacotes | pandas, matplotlib, pymupdf, pypdf | ausentes: geopandas/shapely/duckdb/pytest — piloto feito em stdlib (D7) |

## 4. Riscos principais

1. **GFW_TOKEN** — sem ele não há outcome; ação do pesquisador (5 min).
2. Endogeneidade da localização da AMP (escolhida por valor ecológico) —
   mitigada por SDID com doadores de montes submarinos + pretrends.
3. Frota artesanal invisível ao AIS — claims restritas à frota monitorada;
   Seguro-Defeso/RAIS cobrem a margem artesanal por outra via.
4. Sem série nacional de desembarque → artigo fala de **esforço**, não
   estoque (título e claims já calibrados para isso).
5. Amendment risk: vigências podem ter mudado após 2025 — busca ativa de
   normas posteriores antes de qualquer estimação (gate no registro).
6. Poucos clusters no caso Trindade — inferência por permutação espacial
   pré-registrada.

## 5. Decisão recomendada

**CONTINUAR**, com escopo focado nos casos (A) + (B), condicionado a:
1. pesquisador gerar GFW_TOKEN;
2. pesquisador validar a regra 656/2022 (D8) e a leitura do Decreto 9.312;
3. `renv::init()` + instalação do stack espacial;
4. só então rodar o item 9/11 do teste mínimo com esforço REAL e decidir
   sobre a fase 1 completa.
