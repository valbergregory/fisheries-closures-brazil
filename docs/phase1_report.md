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

## 6. Synthetic DiD (trimestral, doadores >100 km) — `scripts/09_phase1_synthdid.R`

| Zona | SDID | SE placebo | SC | DiD | N1 / N0 |
|---|---:|---:|---:|---:|---|
| MONA | −0,185 | 0,021 | −0,252 | −0,110 | 91 / 1.031 |
| APA | −0,097 | 0,011 | −0,096 | −0,013 | 561 / 1.031 |
| anel 0–10 | −0,090 | 0,025 | −0,186 | −0,084 | 40 / 1.031 |

Com doadores ponderados para reproduzir a trajetória pré, as três zonas
mostram redução e o "aumento na APA" do TWFE desaparece. **Mas o ajuste pré
do MONA é pobre** (série tratada quase nula; o "efeito" é o controle subir
após 2018 enquanto o MONA fica parado — `outputs/figures/synthdid_mona_trindade.png`),
padrão que a seção 7 explica.

## 7. Diagnóstico de cobertura (D13) — `scripts/10_phase1_coverage.R`

Presença AIS (todas as embarcações, `public-global-presence`, 7 extrações
anuais), média de horas por célula-mês:

| Zona | 2014 | 2016 | 2018 | 2020 | 2020/2014 |
|---|---:|---:|---:|---:|---:|
| controle >100 km | 3,99 | 7,01 | 9,38 | 9,46 | **2,4x** |
| anéis 25–100 km | 3,2–3,4 | 6,0–6,2 | 9,8–10,8 | 9,7–10,5 | 3,1x |
| APA | 2,70 | 3,96 | 5,22 | 4,51 | 1,7x |
| MONA | 1,95 | 2,50 | 3,68 | 1,96 | **1,0x** |

**Placebo:** o event study da PRESENÇA reproduz — ampliada — a pré-tendência
da pesca (MONA: leads +0,47/+0,36/+0,19; APA: +0,29/+0,27/+0,08; Wald p≈0;
anel 0–10 km: p = 0,21). Conclusão: **a pré-tendência da seção 3 é
artefato da expansão diferencial da detecção AIS (e/ou do tráfego geral)
no oceano aberto, não comportamento da frota.** A identificação ingênua
"zona vs. oceano aberto" está descartada.

**Correções tentadas e seus limites**
(`outputs/tables/coverage_diagnostics_trindade.csv`):

- *Fração pescando* (pesca/presença): elimina a tendência monotônica; leads
  do MONA ficam em ±0,01 e o efeito pós é ≈ 0 (−0,017/−0,002/0,000); APA
  +0,5/+2,4/+3,0 pp. Wald ainda rejeita por precisão (2.068 células), não
  por magnitude.
- *ihs(pesca) controlando ihs(presença)*: leads planos, mas **o controle é
  endógeno perto das ilhas** — ali a presença É a frota pesqueira (a
  presença do MONA cai −0,42 em 2020, o que é o próprio efeito da UC sobre
  quem vai lá). Controlar por presença total "controla fora" o tratamento.

## 8. Estado ao fim da rodada de 10/09 e o que é necessário

**Identificação NÃO alcançada.** O que os dados exigem antes de qualquer
estimativa reportável:

1. **Medida de cobertura EXÓGENA à pesca** — presença de embarcações
   NÃO-pesqueiras (carga, tanque) por célula-mês. A API 4wings não agrupa
   presença por tipo, mas devolve registros por embarcação (MMSI, ~10 MB/
   ano); cruzando com a Vessel API (shiptype), constrói-se o denominador
   exógeno. Alternativa: rasters de qualidade de recepção AIS publicados
   pelo GFW (fora da API).
2. Com esse denominador: repetir seções 3, 5 e 6.
3. Controles oceanográficos (OISST) — hipótese secundária, ainda não testada.
4. Se (1) não restaurar tendências paralelas: o caso Trindade vira **caso
   de limitação** no artigo ("a criação da UC não é avaliável com AIS no
   período por expansão diferencial de cobertura"), e o peso empírico
   migra para o caso do camarão (B) — cuja região costeira tem o mesmo
   problema em grau maior (D13: 2,28x), o que precisa ser enfrentado com
   a mesma ferramenta.

Ou seja: **a correção de cobertura exógena é o item crítico do projeto
inteiro**, não um refinamento.

## 9. Cobertura EXÓGENA (opção 1, autorizada em 10/09) — resultados

**Dado construído.** Presença AIS por embarcação e célula-mês, 2014–2020
(10 extrações do 4wings agrupadas por `VESSEL_ID`, ~460 MB, com
`vesselType`): CARGO 720 mil h, FISHING 172 mil, OTHER 134 mil, GEAR 51 mil,
CARRIER 7 mil, PASSENGER 6 mil. Agregado em `python/build_exogenous_coverage.py`
→ `cargo_hours`, `nonfish_hours`, `fishing_pres` por célula-mês.

**(a) Placebo com cargueiros — confirma o artefato de detecção.** O event
study de ihs(cargo) por zona reproduz a pré-tendência da pesca (MONA:
+0,27/+0,29/+0,16 → 2017 → −0,03/−0,11/−0,35; APA: +0,14/+0,17/+0,05 →
+0,03/−0,06/−0,20; anéis: p > 0,05). Cargueiros não reagem a UC: **a
detecção AIS perto das ilhas piorou relativamente ao oceano aberto ao longo
de 2014–2020**, com queda forte em 2020. A causa da seção 3 está
identificada com medida exógena.

**(b) Correção — quatro formas funcionais, resultados NÃO convergem no MONA**
(`outputs/tables/{exog_coverage,deflated,ppml}_eventstudy_trindade.csv`):

| Forma | MONA leads (14/15/16) | MONA pós (18/19/20) | APA pós (18/19/20) |
|---|---|---|---|
| ihs(pesca) + controle linear ihs(cargo) | +0,14/+0,10/+0,01 (inalterado) | −0,10/−0,01/−0,05 | 0/+0,10/+0,09 |
| d = ihs(pesca) − ihs(cargo) | −0,14/−0,19/−0,15 | −0,07/+0,10/**+0,30** | −0,04/+0,17/+0,30 |
| razão pesca/cargo | +0,07/−0,05/−0,07 | −0,15/+0,02/**−0,22** | +0,06/+0,34/+0,26 |
| PPML, log(cargo) como exposição | **−13/−13/−14** (separação) | −0,28/−0,22/−1,49 | +1,05/+1,80/+1,61 |

Por que não converge: (i) o controle linear não absorve o lead porque a
covariação célula-mês entre detecção de cargueiros e de pesqueiros é nula —
elasticidade PPML de **−0,09** (cargueiros: AIS classe A, rotas fixas;
pesqueiros: classe B, intermitentes; a recepção de satélite afeta ambos na
tendência, não na célula-mês); (ii) `asinh` não é log em contagens de 0,1–0,3
h, então a "deflação" depende da escala; (iii) a razão é dominada por
denominadores minúsculos; (iv) **no MONA praticamente não há pesca observada
em 2014–2016** (PPML separa) — o "efeito" de qualquer especificação depende
de 2017 ser a referência.

**(c) O que sobrevive.** A **APA** mostra aumento pós-designação em todas as
formas funcionais com cobertura (TWFE +, deflacionado +0,30, PPML +1,8***
com Conley 200 km) — exceto no SDID (−0,10). O **anel 0–10 km** cai em
todas (−0,12 a −0,61; significância some com Conley). O **MONA** não tem
resultado defensável: quase não havia esforço AIS lá antes do decreto.

## 10. Conclusão da fase 1 e reformulação proposta (decisão do pesquisador)

1. A cobertura exógena cumpriu o papel de **diagnóstico** (artefato
   confirmado com medida independente da pesca) mas **não funciona como
   correção no nível célula-mês**. A correção defensável é no nível
   zona-ano (diferença de event studies, que é o que a linha "d" mostra) —
   e ela exige aceitar que a referência 2017 domina o resultado.
2. **A pergunta "o MONA reduziu a pesca?" é vazia para a frota observável
   por AIS**: não havia esforço mensurável dentro do MONA antes de 2018. O
   artigo deve dizer isso — é um achado de SI/limitação, não um resultado
   nulo.
3. **A pergunta que os dados sustentam é outra: a designação da APA (uso
   sustentável) ATRAIU esforço para dentro dela**, vindo do anel
   imediatamente externo — consistente em TWFE, deflacionado e PPML, com
   Conley. Um "efeito de sinalização" da designação, inverso ao leakage
   clássico. Falta: reconciliar com o SDID (que discorda), testar com
   controles oceanográficos (OISST) e com placebos geográficos (APA
   deslocada), e verificar se o aumento é de embarcações novas na região
   ou realocação das existentes (dado por `VESSEL_ID` já baixado permite).
4. Reformulação sugerida do caso principal: de "closures reduce effort?"
   para **"sustainable-use designation attracts effort: evidence from
   Brazil's largest MPA"**, mantendo o defeso do camarão como caso de
   restrição temporal. A decisão é do pesquisador.
