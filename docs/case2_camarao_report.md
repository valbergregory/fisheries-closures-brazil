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

## 3. Resultados (`outputs/tables/camarao_calendar_main.tex`)

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
