# Caso II — Reforma do calendário do defeso do camarão SE/S (Portaria SAP/MAPA 656/2022)

Fase 1, Bloco B, executado em 2026-09-11 sem intervenção do pesquisador.
Scripts: `python/build_camarao_panel.py`, `scripts/19–21`. Área e geometria
PROVISÓRIAS (D3 pendente).

## 1. Desenho

Tratamento = mudança de calendário: até 2022 o defeso era 1º/mar–31/mai; desde
2023 é 28/jan–30/abr. Para as mesmas células e a mesma frota, **fevereiro
passou de livre a proibido** (C1) e **maio passou de proibido a livre** (C2);
março–abril continuam proibidos; junho–dezembro continuam livres (referência);
janeiro é misto (28–31 proibido só no pós). Modelo: ihs(horas de arrasto)
com efeitos fixos **célula × mês-do-ano** e **ano**, controle de cobertura
ihs(presença AIS total na célula-mês) e SST. Comparação dentro-célula, entre
anos — imune ao gradiente espacial de detecção que inviabilizou Trindade.

## 2. Dados

Área: 1.508 células de 0,25° entre 21°18'S (divisa ES–RJ) e 33°45'S, a até
200 km de terra (máscara OISST). 2018–2024 (84 meses). Esforço por
`VESSEL_ID`: 1.517 embarcações de arrasto, 1.106 com AIS anterior a
28/01/2023 ("frota pré-2023"). Presença AIS total como cobertura: cresceu
3,9 → 6,9 mi h/ano (1,8x) — daí o controle. Horas de arrasto: 187 mil (2018)
→ 563 mil (2023); frota pré-2023: 422 mil (2023), 270 mil (2024).

| Mês (status) | A toda frota | C pré-2023 + cobertura | D + SST | E PPML pré-2023 | G cluster duplo |
|---|---:|---:|---:|---:|---:|
| fev (livre → **proibido**) | **−0,160\*\*\*** | −0,094\*\*\* | −0,089\*\*\* | −0,353\*\*\* | −0,089\*\* |
| mai (proibido → **livre**) | **+0,194\*\*\*** | +0,237\*\*\* | +0,238\*\*\* | +0,892\*\*\* | +0,238\*\*\* |
| mar–abr (proibido nos dois) | −0,056\*\* | −0,004 | +0,002 | +0,184\*\* | +0,002 |
| jan (misto) | −0,013 | +0,052\*\* | +0,066\*\*\* | +0,481\*\*\* | +0,066 |

**Event study anual** (ref. 2022; `outputs/figures/camarao_eventstudy.png`):
- **Maio**: leads 2018–2021 = −0,01/+0,01/−0,04/+0,03 (todos n.s.); pós =
  **+0,231\*\*\* (2023), +0,294\*\*\* (2024)**. Pré-tendência limpa.
- **Fevereiro**: leads −0,02/+0,06\*/+0,01/−0,06\*; pós −0,070\* (2023),
  −0,057 (p=0,08). Efeito moderado, pré-tendência ruidosa.
- Janeiro: leads em alta (−0,09 → +0,07); pós +0,098\*\*\*/+0,044.

**Placebo temporal** (reforma fictícia em 2021, amostra 2018–2022;
`camarao_placebo_temporal.csv`): maio **+0,024 (n.s.)**; fevereiro −0,038\*;
janeiro **+0,090\*\*\*** (a "antecipação" de janeiro é tendência prévia, não
efeito); mar–abr −0,015 (n.s.).

## 4. Leitura

1. **C2 identificado**: a liberação de maio elevou o esforço de arrasto em
   ≈ 24–29 % (ihs) na frota continuamente observável, com pré-tendências
   nulas e placebo nulo. O sinal é o previsto e o oposto do de fevereiro —
   o placebo interno de direção passa.
2. **C1 parcialmente identificado**: o fechamento de fevereiro reduziu o
   esforço em ≈ 9 % na frota pré-2023 (≈ 16 % na frota toda), mas o placebo
   de 2021 captura ≈ 4 %, logo o efeito líquido defensável é da ordem de
   −5 %. **Cumprimento parcial** do novo mês fechado — coerente com H1/H6.
3. **Assimetria**: a frota responde mais à abertura do que ao fechamento —
   um achado econômico em si (custo de oportunidade de não pescar em maio
   vs. custo esperado de infringir em fevereiro).
4. Antecipação em janeiro (C3): **não identificada** (placebo positivo).
5. Outras artes sobem em todos os meses tratados (mF) — não é substituição
   específica; provável crescimento geral da observação de outras artes.
   C5 (substituição de arte/espécie, variantes D8) fica em aberto.
6. Inferência: cluster por célula e duplo (célula, ano-mês) coincidem;
   Conley indisponível neste ambiente para 126k linhas (segfault) —
   pendente wild bootstrap por UF e permutação de anos.

## 5. O que falta (por ordem)

- Ratificar a geometria (D3): mar territorial + ZEE de RJ–RS vs faixa de
  200 km; excluir/tratar o ES (calendário dez–fev) como controle (C4).
- Cobertura EXÓGENA (cargueiros por célula-mês) para o camarão — exige
  presença por `VESSEL_ID` na costa (arquivos ~50 MB/semestre; 14 extrações).
- C5 com as duas leituras do §3º (D8).
- C6 Seguro-Defeso: série 2021-03+ (CGU respondeu 405 em 11/09; retentar).
- Inferência por permutação de anos e wild cluster bootstrap por UF.
- Decomposição de leakage temporal (protocolo §7): redução em fev + aumento
  em mai + variação em mar–abr = mudança líquida — implementável já.

## 6. Adendo de 2026-09-12 — decomposição, meses-placebo e substituição (`scripts/22`)

**Decomposição temporal do leakage** (PPML, frota pré-2023, 2023–2024;
`camarao_leakage_decomposition.csv`): fevereiro −9.519 h; maio +48.813 h;
mar–abr +7.772 h; janeiro +25.519 h; **líquido +72.585 h (+33 % do
observado nos meses tratados)**. Antecipar o defeso liberou mais esforço em
maio do que retirou em fevereiro — a mudança líquida de pressão nos meses
afetados é POSITIVA. (Janeiro e mar–abr têm identificação fraca — ver abaixo.)

**Randomização sobre meses-placebo** (jun–dez tratados um a um como se fossem
o mês reformado; `camarao_placebo_months.csv`): coeficientes de −0,117 (dez)
a +0,194 (jun), dp 0,11. **Maio (+0,238) é o maior de todos os meses
(rank 1/8, p_RI = 0,125)**, mas junho (+0,194) é vizinho próximo — leitura
mais plausível: transbordamento da abertura (temporada antecipada para
mai–jun), não falha do placebo. **Fevereiro (−0,090) NÃO se distingue de
dezembro (−0,117) nem de set–nov (−0,06)**: C1 não é identificável contra
meses-placebo. Conclusão revisada: **C2 identificado em magnitude, marginal
em RI com 7 placebos; C1 não identificado.**

**C5 — substituição por arte** (`camarao_gear_substitution.csv`, frota
pré-2023): em fevereiro, espinhel de deriva +0,190\*\*\* e "fishing"
genérico +0,087\*\*\* sobem enquanto o arrasto cai −0,089\*\*\*; espinhel de
fundo ≈ 0. Compatível com substituição de arte no mês recém-fechado (H2 na
margem de modalidade), mas as duas artes também sobem em maio e mar–abr —
parte é crescimento geral pós-2023. Precisa da leitura D8 e de decomposição
por embarcação (o mesmo barco muda de arte?) para fechar.

**Estado do caso após o adendo**: o resultado defensável é (i) a abertura de
maio elevou o esforço de arrasto ~24–29 % (maior efeito entre todos os meses,
leads e placebo temporal nulos), (ii) o fechamento de fevereiro teve
cumprimento parcial não distinguível da variação mensal placebo, (iii) o
saldo líquido da reforma nos meses afetados é um aumento de esforço. A
narrativa muda de "cumprimento" para **"realocação assimétrica: a frota
captura a abertura mais do que respeita o fechamento"**.

## 7. C6 — Seguro-Defeso acompanha o novo calendário (2026-09-12, `scripts/25`)

Série CGU completa 2019-01–2024-12 (72 meses; 107.927 município-mês;
microdados fora do Git, D9). Beneficiários por mês de competência em
RJ+SP+PR+SC+RS, participação no total anual, média 2023–24 menos 2019–22
(`seguro_defeso_calendar_shift.csv`):

| Meses | Δ participação (p.p.) |
|---|---:|
| janeiro–fevereiro | **+10,1** |
| março–abril | −0,6 |
| maio–junho | **−5,4** |

Em todas as UFs o sinal é o mesmo (jan–fev: PR +16,6, RJ +11,3, SC +10,8,
SP +10,1, RS +7,2; mai–jun: PR −12,9, SC −7,2, SP −4,9, RJ −3,8, RS −2,1).
A compensação foi reprogramada exatamente para o novo período: o mecanismo
de renda de reserva (H5) esteve ativo nos meses recém-fechados. Cautelas:
o benefício cobre todos os defesos (não só camarão); 2019 tem janeiro
anômalo (2,2 %), possivelmente início incompleto da série; 2024 tem
dezembro baixo (competência ainda não paga na extração). Ainda não testado:
tempestividade (atraso entre competência e pagamento) — os microdados
trazem só a competência.

## 8. Cobertura EXÓGENA no camarão (2026-09-12, `scripts/24`) — o resultado não é artefato de detecção

Presença por embarcação na costa (14 extrações, 5,3 GB, `vesselType`):
cargueiros/tanques 93 → 125 h/célula-mês (2018 → 2024).
**Placebo com cargueiros**: em maio a detecção de cargueiros CAIU pós-2023
(−0,123\*\*\*) enquanto o arrasto SUBIU (+0,238\*\*\*) — direção oposta,
logo o efeito de maio não pode ser detecção. Fevereiro: cargo −0,063 vs
arrasto −0,089 — mesma direção, parte pode ser detecção.
**Com cobertura exógena como controle** (`camarao_exog_coverage.tex`):
maio +0,242\*\*\* (cargo) / +0,247\*\*\* (não-pesqueiros); fevereiro
−0,070\*\* / −0,069\*\* (era −0,089 com presença total). Conclusão: **C2
robusto a detecção; C1 encolhe para ≈ −7 % e segue não distinguível dos
meses-placebo (§6).**

## 9. Estado consolidado do caso II (2026-09-12)

| Estimando | Resultado | Identificação |
|---|---|---|
| C2 maio (proibido → livre) | +0,24 (2023) / +0,29 (2024), ihs; PPML +0,89 | leads nulos, placebo temporal nulo, maior entre 12 meses (RI p=0,125), robusto a cobertura exógena e SST |
| C1 fevereiro (livre → proibido) | −0,07 a −0,09 (frota pré-2023); −0,16 (toda a frota) | não distinguível de meses-placebo; parte é detecção |
| C3 antecipação (janeiro) | +0,07 | placebo temporal +0,09 → NÃO identificado |
| C5 substituição de arte | espinhel de deriva +0,19, "fishing" +0,09 em fevereiro | provisório (depende da D8 e de decomposição por embarcação) |
| C6 Seguro-Defeso | jan–fev +10,1 p.p.; mai–jun −5,4 p.p. em todas as UFs | descritivo; mecanismo operante |
| Leakage temporal líquido | +72,6 mil h (+33 %) nos meses tratados, 2023–24 | dominado por maio |

Pipeline `targets` (21 alvos) reproduz tudo em ~3 min a partir dos painéis;
`Rscript scripts/04_run_pipeline.R`.

---

# REANÁLISE DE 2026-09-22 — geometria corrigida (D3). As seções 1–9 acima
# ficam SUPERADAS nos números; a metodologia permanece.

## 10. O que mudou e por quê

A coluna `dist_land_km` usada até 12/09 vinha da máscara terra/mar do OISST
(0,25°), que trata quase toda a faixa costeira como oceano: a célula de maior
esforço (−48,375; −26,875, em frente a Itajaí) aparecia a **159 km** da costa
quando está a **23 km**. Com a distância geodésica à linha de costa do IBGE
(`scripts/27_coast_distance.R`), a área de estudo passou a ser (D3): células
oceânicas de 0,25° adjacentes a RJ–RS, **excluídas as águas interiores**
(dentro dos polígonos estaduais: Lagoa dos Patos, baías — a Portaria alcança
apenas MT e ZEE), **raio principal 100 km** (86 % do esforço; 64 % está a
≤50 km). `R/24_camarao_prep.R` passa a ser a preparação canônica.

## 11. Resultados (painel 324 células × 84 meses = 27.216 obs; 1.106 barcos de arrasto pré-2023)

| Janela | (1) toda a frota | (3) frota pré-2023 | (4) + SST | (5) PPML | cluster UF | WCB (Webb, G=5) |
|---|---:|---:|---:|---:|---:|---:|
| **fevereiro** (livre→fechado) | −0,703\*\*\* | −0,334\*\*\* | **−0,314\*\*\*** (0,085) | — | −0,314 (0,274) | **p = 0,39** |
| **maio** (fechado→livre) | +0,600\*\*\* | +0,640\*\*\* | **+0,631\*\*\*** (0,073) | — | +0,631\*\* (0,129) | **p = 0,025** |
| mar–abr (fechado nos dois) | −0,086 | +0,092 | +0,116 | — | +0,116 (0,259) | p = 0,82 |
| janeiro (parcial) | −0,058 | +0,246\*\*\* | +0,323\*\*\* | — | +0,323 (0,169) | p = 0,28 |

Em nível: maio ≈ **+88 %** de horas de arrasto; fevereiro ≈ **−27 %**.

**Event study** (`fig3`): maio tem leads +0,14/+0,02/−0,01 (nulos) e pós
**+0,691\*\*\*/+0,629\*\*\***; fevereiro tem leads −0,20/+0,06/−0,01 e pós
**−0,354\*\*\*/−0,334\*\***. Janeiro e março têm tendência prévia forte e
**não são interpretáveis**.

**Placebos.** (i) Meses-placebo (`fig4`): fevereiro e maio são os **dois
extremos** entre os 8 meses (rank 1/8 cada; dp dos placebos 0,268).
(ii) Temporal (reforma fictícia em 2021): fevereiro +0,042 (n.s.), maio
+0,161 (p = 0,063) — um décimo e um quarto dos efeitos reais.
(iii) **Cargueiros** (detecção exógena): fevereiro −0,001 (n.s.) e maio
**−0,074\*\*\*** — em maio a detecção CAI enquanto o arrasto SOBE, direções
opostas. Com cargueiros como controle: fevereiro −0,346\*\*\*, maio
+0,773\*\*\*.
(iv) **Especificidade espacial** (`fig5`, D18): o efeito decai
monotonicamente com a distância à costa e desaparece além de 150 km, onde
não há pescaria de camarão (0–50 km: −0,426/+0,680; >150 km: +0,011/+0,070).

**Substituição de arte** (`fig6`): na frota pré-2023, a participação do
arrasto nas horas de fevereiro cai de **68,1 % para 47,2 %** enquanto o
espinhel de fundo sobe de 21,7 % para 30,0 % e as artes não classificadas de
6,4 % para 16,8 %. Em maio o espelho: arrasto de **45,6 % para 75,1 %**,
espinhel de 30,4 % para 11,5 %.

**Decomposição temporal** (`fig8`): fevereiro −9,5 mil h; maio +47,6 mil h;
mar–abr +11,4 mil h; janeiro +24,4 mil h → **líquido +73,9 mil h (+36 %)**
sobre o contrafactual, em 2023–24.

**Heterogeneidade por UF** (`camarao_by_uf.csv`): maio é positivo nas cinco
UFs (PR +1,24; SC +0,83; RS +0,74; SP +0,36; RJ +0,25). Fevereiro é negativo
em quatro (PR −1,47; SP −0,82; RJ −0,34; SC −0,20) e **positivo no RS
(+0,32)** — a dispersão entre UFs é o que derruba a significância no wild
bootstrap com G = 5.

**Compensação** (`fig7`): Seguro-Defeso em RJ–RS desloca **+10,1 p.p.** para
janeiro–fevereiro e **−5,4 p.p.** de maio–junho (média 2023–24 vs 2019–22),
com o mesmo sinal nas cinco UFs.

## 12. C4 (Espírito Santo como controle espacial) — NÃO VIÁVEL

O ES tem calendário próprio (Art. 3º: 1º/dez–28/fev) e frota confinada ao
estado (Art. 8º §1º), o que faria dele um controle ideal. Mas a extração
(14 semestres, `data/raw/es/`) encontra **19 embarcações de arrasto e 2.271
horas em sete anos**, contra 2,29 milhões de horas em RJ–RS. A frota de
arrasto capixaba é pequena e/ou não observável por AIS: o controle não tem
potência. Registrado como limitação; reforça o argumento de observabilidade.

## 13. Leitura final do caso II

1. **Maio (abertura) é o resultado firme**: +88 % de esforço, leads nulos,
   placebos nulos, direção oposta à da detecção, presente nas cinco UFs e
   sobrevivente ao wild bootstrap com 5 clusters.
2. **Fevereiro (fechamento) é forte no desenho principal mas frágil na
   inferência conservadora** (p = 0,39 com G = 5), porque o RS vai na direção
   contrária. Leitura honesta: cumprimento parcial e heterogêneo.
3. **A resposta é assimétrica** — a frota captura a abertura mais do que
   respeita o fechamento — e **em parte é de composição, não de nível**:
   quando o arrasto fecha, a mesma frota migra para espinhel.
4. **O saldo da reforma é positivo em esforço** (+36 %), não neutro.

## 14. Controle geográfico nacional (23/09) — resposta à pergunta "por que não usar toda a costa?"

A pergunta do pesquisador apontou uma extensão que faltava. A reforma vale só
para RJ–RS; o **Norte** (Portaria MDIC/MMA 75/2017, defeso 15/12–15/02) e o
**Nordeste** (IN MMA 14/2004) têm defesos próprios que **não mudaram em
2023** — logo o resto da costa é controle externo. Extraímos os mesmos dados
(28 requisições; `data/raw/costa/`), aplicamos o mesmo critério D3 e
estimamos a mesma especificação em cada trecho (`scripts/34`, `scripts/35`):

| Região | células | horas de arrasto | fevereiro | maio |
|---|---:|---:|---:|---:|
| Norte (AP–MA) | 217 | 51.274 | +0,006 (p=0,81) | +0,001 (p=0,95) |
| Nordeste (PI–BA) | 329 | 1.855 | −0,037\*\*\* | −0,003 (n.s.) |
| **Sudeste/Sul (reformado)** | 324 | 2.288.501 | **−0,334\*\*\*** | **+0,640\*\*\*** |

**Triplas diferenças**: fevereiro **−0,331\*\*\*** e maio **+0,735\*\*\***
(p<0,001); com efeitos fixos região×ano, −0,332 e +0,736 — inalterados.
`outputs/tables/ddd_costa.tex`, figura `fig9_controle_geografico.png`.

Isso resolve em boa parte a fragilidade de fevereiro: o problema era a
inferência com cinco conglomerados, e agora há um contrafactual externo — o
arrasto de fevereiro não se moveu onde o calendário não mudou. O Nordeste tem
efeito pequeno e significativo, mas sobre 1.855 horas (0,08 % do SE/S).

## 15. Robustez econométrica adicional (`scripts/33`)

| Teste | fevereiro | maio |
|---|---|---|
| asinh (principal) | −0,314\*\*\* | +0,631\*\*\* |
| log(1+h) | −0,301\*\*\* | +0,559\*\*\* |
| nível (horas) | −44,8\*\*\* | +71,2\*\*\* |
| margem extensiva (presença) | −0,006 (n.s.) | +0,101\*\*\* |
| fração pesca/presença | −0,040\*\*\* | +0,106\*\*\* |
| *leave-one-state-out* | −0,074 (sem SP) a −0,580 (sem RS) | +0,544 a +0,741 |
| sensibilidade a tendências não paralelas (M que anula) | 1,12 | **2,45** |
| bootstrap de blocos latitudinais (IC 95 %) | [−0,749; +0,118] | **[+0,395; +0,932]** |
| tercil de intensidade pré (alto) | −0,700 | +1,168 |

Leituras: (i) fevereiro opera na **margem intensiva** (menos horas por célula
ativa), maio nas duas; (ii) fevereiro **depende de São Paulo**; (iii) o efeito
está concentrado nas células de maior intensidade pré-reforma — dose-resposta;
(iv) maio passa em todos os testes, fevereiro em nenhum dos conservadores,
mas é sustentado pelo controle nacional (§14).

**Notas sobre estimadores heterogêneos**: como o tratamento é simultâneo
(2023) e binário, Callaway–Sant'Anna e Sun–Abraham coincidem com o TWFE aqui —
não há coortes escalonadas nem problema de comparações "proibidas". O
`HonestDiD` não está disponível no CRAN neste ambiente; a sensibilidade de
Rambachan–Roth foi implementada na variante *relative magnitudes*.
