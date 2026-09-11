# Ponto de retomada — atualizado em 2026-09-11 (noite)

## Estado em uma frase
Fase 1 do caso Trindade concluída até o limite do que o AIS permite: o
artefato de cobertura foi confirmado com medida exógena, o MONA não é
avaliável (quase zero pesca observada antes do decreto), e o achado que
sobrevive é **a APA de uso sustentável atraiu esforço após a designação**.

## 11/09 (noite): Blocos A, B e C executados — ver docs/phase1_report.md §13 e docs/case2_camarao_report.md
**Trindade encerrado como não identificável (D15).** **Camarão identificado:**
maio (proibido→livre) +0,24/+0,29 com pré-tendências e placebo nulos;
fevereiro (livre→proibido) ≈ −5 a −9 % (cumprimento parcial); janeiro
"antecipação" = tendência prévia. Registro: 19 regras. Seguro-Defeso 2019-01..
2021-02 (CGU 405 depois). Título/estrutura: docs/title_and_structure_proposal.md.
Estimandos v0.2: docs/estimand_table.md. **Rodar scripts R diretamente
(`Rscript scripts/XX.R`), nunca via source() de wrapper — segfault.**

## 11/09 (manhã): D14 APROVADA e passo 1 executado (commit 425adbc)
A decomposição por embarcação (`scripts/14`, `scripts/15`, report §§11–12)
mostrou que ~70% da "atração" da APA é adoção de AIS pela frota de espinhel
após 2018. Na frota continuamente observável o efeito APA é frágil; o
resultado robusto a tudo é a **queda no anel 0–10 km fora da APA**
(−12%, p<0,05 Conley, pré-tendência ok). Próximo item: catalogar mandatos
de AIS (NORMAM/Marinha, PREPS) no Knowledge Base como "políticas de
observabilidade" e verificar se explicam a adoção em 2018; depois SDID na
frota pré-AIS, OISST, placebos, 2021–24.

## Decisão pendente anterior (resolvida em 11/09 — mantida para histórico)
Aceitar a reformulação do caso principal proposta em
`docs/phase1_report.md`, seção 10: de "closures reduce effort?" para
"sustainable-use designation attracts effort" (MONA vira achado de
limitação; camarão continua como caso temporal).

## Se aceita, próximos passos (nesta ordem)
1. Reconciliar o synthetic DiD (único que discorda da APA) — investigar
   pesos e ajuste pré; `outputs/models/synthdid_trindade_phase1.rds`.
2. Controles oceanográficos: SST OISST (rota testada no projeto irmão
   marine-fisheries-data-cube: OPeNDAP em fatias ≤183 dias).
3. Placebos geográficos: APA deslocada ao longo do oceano; datas placebo.
4. Decompor o aumento na APA por `VESSEL_ID` (dado já em
   data/raw/presence_vessel/): embarcações NOVAS na região vs REALOCADAS
   do anel externo — distingue atração de deslocamento.
5. Estender pós-período (2021–2024) e testar persistência.
6. Só então: pré-registro final dos estimandos (docs/estimand_table.md
   precisa ser reescrita para a nova pergunta) e artigo.

## Como reproduzir o estado atual
```r
renv::restore()
# Background Jobs, nesta ordem (todos leem data/interim e escrevem em outputs/):
#   python python/feasibility_pilot.py      # grade + calendário (config.yml: 2014-2020)
#   python python/merge_gfw_pilot.py        # esforço GFW -> painel
#   python python/merge_gfw_presence.py     # presença total
#   python python/build_exogenous_coverage.py  # cargo/nonfish por célula-mês
#   scripts/08_phase1_trindade_rings.R      # anéis sf + TWFE + decomposição
#   scripts/09_phase1_synthdid.R            # SDID trimestral
#   scripts/10_phase1_coverage.R            # placebo presença total
#   scripts/11_phase1_exog_coverage.R       # placebo cargo + controles
#   scripts/12_phase1_deflated.R            # diferença ihs + Conley
#   scripts/13_phase1_ppml.R                # PPML com exposição
```
Dados brutos (fora do Git, checksums em `data/metadata/checksums_gfw.txt`):
`data/raw/gfw_effort_trindade_20{14..20}*.json`, `gfw_presence_trindade_*.json`,
`presence_vessel/*.json` (~400 MB). Se faltarem, re-extrair com o token em
`.Renviron` — a API do GFW aceita no máximo 366 dias por requisição e, para
presença por embarcação, pedir por SEMESTRE (ano inteiro dá 524/429).

## Pegadinhas do ambiente (Windows)
- Shell bash pode perder o PATH: prefixar `export PATH="/usr/bin:/bin:/mingw64/bin:$PATH"`.
- Heredoc colapsa barras invertidas: não escrever regex com escapes em heredoc.
- Git Credential Manager parou de responder: push via PowerShell com
  `GIT_ASKPASS` temporário alimentado por `gh auth token` (apagar depois).
- Rscript fora do PATH: `C:\Program Files\R\R-4.4.3\bin\Rscript.exe`.

## Registro regulatório (independente da decisão acima)
6 regras em `outputs/policies/` (656/2022 validada; sardinha ×3 e
piramutaba ×2 aguardam validação humana). 20 normas do corpus ainda sem
regra estruturada — trabalho de SI que pode avançar em paralelo.
