# Relatório da fase 1 — caso Trindade (iniciado 2026-09-10)

Autorizado pela decisão D1 (aprovada em 10/09). Este documento registra o
que a fase 1 produziu, na ordem em que foi produzido, incluindo o que NÃO
funcionou. Nada aqui é resultado final.

## 1. Motor espacial (R/sf) — concluído

- Distâncias GEODÉSICAS (sf 1.1.2 + s2), sem reprojeção → fecha D4 para o caso.
- Zonas mutuamente exclusivas por centro de célula (0,25°): `mona` (91
  células), `apa` fora do MONA (561), anéis externos à APA 0–10 km (40),
  10–25 (50), 25–50 (88), 50–100 (207), controle >100 km (1.031).
- Funções: `R/10_build_spatial_rules.R`, `R/11_build_treatment.R`,
  `R/19_spillovers.R`, `R/15_event_study.R`; runner
  `scripts/08_phase1_trindade_rings.R`.
- Painel: 2.068 células × 84 meses (2014-01–2020-12) = 173.712 linhas,
  `data/processed/panel_trindade_phase1.csv`.

## 2. Modelo estático por zona (TWFE, FE célula + ano-mês, cluster célula)

| Zona | ihs(horas) | presença | leitura ingênua |
|---|---:|---:|---|
| MONA | −0,091*** | −0,040*** | queda |
| APA | +0,019 (ns) | −0,002 | nada |
| anel 0–10 km | −0,109*** | −0,042*** | queda |
| anel 10–25 | +0,047 | +0,012 | nada |
| anel 25–50 | +0,103*** | +0,026** | aumento |
| anel 50–100 | +0,135*** | +0,047*** | aumento |

**Esta tabela NÃO deve ser interpretada causalmente** — ver seção 3.

## 3. Teste de pré-tendências — FALHOU para MONA e APA

Event study anual, efeitos fixos de célula, ano-mês e **sazonalidade
própria de cada zona** (zona × mês do ano), referência 2017, controle
>100 km (`outputs/tables/pretrend_tests_trindade.csv`,
`outputs/figures/eventstudy_annual_trindade_phase1.png`):

| Zona | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | Wald leads (p) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| MONA | +0,133*** | +0,096*** | +0,011 | ref | −0,094*** | −0,008 | −0,048* | ≈0 |
| APA | +0,156*** | +0,119*** | +0,037** | ref | −0,002 | +0,103*** | +0,093*** | ≈0 |
| anel 0–10 | −0,055 | −0,084 | −0,047 | ref | −0,140*** | −0,212*** | −0,040 | 0,074 |
| anel 10–25 | −0,144** | −0,167** | −0,019 | ref | +0,151* | −0,022 | −0,069 | <0,001 |

Leitura: **MONA e APA vêm em queda monotônica relativa ao controle desde
2014**, muito antes do decreto. Os "efeitos" pós-2018 têm a mesma ordem de
grandeza dos movimentos pré. A hipótese de tendências paralelas não se
sustenta nesta especificação. Só o anel 0–10 km passa (p = 0,074), e com
efeito de sinal negativo — o oposto do leakage clássico (H2).

Nota: com apenas 2016–2017 como pré-período (versão anterior do painel), o
teste "passava" para MONA e anel — porque tinha um único lead. **Um teste de
pré-tendência com um lead não é um teste.** Foi a extensão para 2014 que
revelou o problema.

## 4. Diagnóstico provável e o que vem a seguir

A causa mais plausível é a **D13**: expansão diferencial da cobertura AIS —
o controle (oceano aberto, rotas de navegação) ganhou recepção mais rápido
que as zonas próximas às ilhas — ou uma migração real da frota de espinhel
para longe das ilhas ao longo de 2014–2017 (oceanográfica). Os dois têm
remédios distintos e ambos serão tentados, nesta ordem:

1. **Normalização por cobertura**: `public-global-presence` do GFW (horas
   de presença de todas as embarcações) como denominador ou controle — a
   presença de navios não-pesqueiros mede recepção independente da pesca.
   Extração em andamento.
2. **Controles ambientais** (SST OISST; clorofila se acessível) para a
   hipótese oceanográfica.
3. **Synthetic DiD** (pacote `synthdid`, já instalado) — pondera doadores
   para reproduzir a trajetória pré da zona tratada; é o desenho
   pré-registrado para "unidade tratada única".
4. **Sensibilidade a violações de tendências paralelas** (Rambachan–Roth,
   `HonestDiD`) — reporta o quanto de desvio da tendência pré o resultado
   tolera.
5. Se nada disso restaurar a identificação, o artigo diz isso: a criação
   da UC de Trindade **não é avaliável com AIS** no período, e o caso passa
   a ilustrar a seção de limitações/SI. Preferível a um resultado falso.

## 5. Decomposição de leakage — suspensa

A decomposição (protocolo, seção 7) foi implementada
(`leakage_decomposition()` em `R/19_spillovers.R`,
`outputs/tables/leakage_decomposition_trindade.csv`), mas só será reportada
quando a identificação for restaurada; sem tendências paralelas, a soma das
parcelas não tem interpretação causal.
