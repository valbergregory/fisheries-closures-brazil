# Tabela de estimandos — v0.2 (2026-09-11, após o Bloco A)

Substitui a v0.1 (escrita para a pergunta original). Reflete o que a fase 1
mostrou: o caso Trindade não é identificável por AIS (D15) e passa a
alimentar estimandos de **observabilidade**; o peso causal migra para o
defeso do camarão (desenho temporal). Toda linha marca a ameaça que a fase 1
já materializou.

## A. Estimandos de observabilidade (contribuição de SI — dados já produzidos)

| # | Pergunta | Unidade | Quantidade estimada | Fonte | Resultado da fase 1 | Uso no artigo |
|---|---|---|---|---|---|---|
| O1 | A detecção AIS perto de ilhas oceânicas diverge da detecção em oceano aberto ao longo do tempo? | célula×ano | leads do event study de ihs(presença de cargueiros) por zona vs controle >100 km | presença por VESSEL_ID com `vesselType` | MONA +0,27/+0,29/+0,16 → −0,35 (2020); APA +0,14/+0,17/+0,05 → −0,20; p≈0 | mecanismo 1: gradiente de detecção |
| O2 | A adoção de AIS pela frota é espacialmente concentrada na área designada? | embarcação | participação das embarcações com 1ª transmissão ≥ data do decreto nas horas pós, por zona | `firstTransmissionDate` | APA 68,9 % / MONA 76,9 % vs controle 25,8 % | mecanismo 2: composição da frota observável |
| O3 | A adoção de AIS responde a mandato regulatório? | embarcação×mês | distribuição da 1ª transmissão vs datas de normas | `config/observability_mandates.yml` | gradual (10–19/ano, 2015–2020); PREPS é VMS, não AIS | KB: categoria "políticas de observabilidade" |
| O4 | Quanto do "efeito" ingênuo de uma UC é artefato? | zona | diferença entre o coeficiente ingênuo e o coeficiente na frota pré-AIS com controles | painéis da fase 1 | APA: +1,8 (PPML, toda a frota) → +0,9 ns (pré-AIS) → indistinguível de placebos (p=0,33) | quantifica o viés |

## B. Estimandos causais — defeso do camarão SE/S (Portaria SAP/MAPA 656/2022)

Tratamento = mudança de calendário: a partir de 2023, 28/jan–28/fev passa de
LIVRE a PROIBIDO e maio passa de PROIBIDO a LIVRE, para as mesmas células e a
mesma frota de arrasto. Desenho dentro-célula, entre anos — imune ao gradiente
espacial de detecção (O1), exposto à tendência temporal de cobertura (D13).

| # | Pergunta | Unidade | Tratamento | Outcome | Comparação | Estimando | Ameaça | Teste |
|---|---|---|---|---|---|---|---|---|
| C1 | O esforço de arrasto cai na janela que passou a ser proibida (28/jan–28/fev)? | célula×mês | ano ≥ 2023 × mês∈{jan(2ª quinzena),fev} | horas de arrasto (ihs; PPML) | mesma célula, mesmos meses, 2019–2022 | DiD dentro-célula com FE célula×mês-do-ano + ano | crescimento de cobertura AIS entre anos; adoção pela frota de arrasto | controle por ihs(presença total) por célula-mês; frota pré-2023 apenas; placebo em meses não afetados (mar–abr, jun–dez) |
| C2 | O esforço sobe na janela que passou a ser livre (maio)? | idem | ano ≥ 2023 × mês = maio | idem | idem | idem, sinal esperado OPOSTO a C1 | idem | placebo interno de direção: C1 < 0 e C2 > 0 simultaneamente |
| C3 | Há antecipação em janeiro (antes de 28/jan) e compensação em junho? | célula×semana (se viável) | idem | idem | idem | coeficientes de leads/lags | sazonalidade biológica | harmônicos; SST |
| C4 | Há deslocamento espacial para fora da área da portaria (ES, onde o calendário é dez–fev)? | célula×mês | idem | horas de arrasto em ES | ES vs RJ–RS | DDD | frota do ES é registrada no ES (Art. 8º: não pode operar fora) | verificar bandeiras/RGP |
| C5 | Substituição de modalidade dentro do defeso (espécie permitida sem arrasto motorizado, D8 variantes a/b)? | célula×mês | idem | horas de artes não-arrasto | idem | DiD por arte | classificação de arte do GFW | robustez às duas leituras do §3º |
| C6 | O Seguro-Defeso acompanha o novo calendário? | município×competência | 2023+ | nº beneficiários, valor, tempestividade | 2019–2022 | mudança de timing dos pagamentos | série CGU incompleta (405 a partir de 2021-03) | completar série |

## C. Estimandos suspensos (Trindade — D15)

E1–E5 da v0.1 (MONA/APA/anéis) ficam **suspensos**: nenhum passa em
placebos geográfico e temporal. Reportados apenas como ilustração de O4.

## D. Inferência

Poucos clusters espaciais no camarão também (a área é uma faixa contínua):
Conley 200 km + permutação temporal (anos placebo) + wild cluster bootstrap
por UF.
