# Inventário de dados

Versão narrativa; a versão máquina-legível está em
[`config/data_sources.yml`](../config/data_sources.yml). Testes executados em
**2026-09-03** com requisições mínimas (nenhum download em massa). Testes
marcados (†) foram herdados da auditoria do projeto irmão
`marine-fisheries-data-cube`, executada no mesmo dia.

## Núcleo — fase 1

### 1. Normas de defeso — IBAMA / DOU / Planalto — **ACESSÍVEL, TESTADO**
- Tabela oficial de defesos marinhos (gov.br/ibama): **~30 defesos** com
  espécie, área, período e norma; PDFs das normas baixáveis.
  **Recuperados hoje:** Portaria SAP/MAPA 656/2022 (PDF 864 KB, íntegra, 8 p.
  + versão DOU HTML) e Decreto 9.312/2018 (Planalto, HTML).
- Atenção: o site clássico `www.ibama.gov.br` bloqueia clientes não-browser
  (HTTP 403); usar sempre os caminhos `gov.br/ibama`.
- IN IBAMA 189/2008 (regime histórico do camarão SE/S): link do
  gov.br/agricultura **quebrado (404)** — recuperar via DOU/INLABS na fase 1.

### 2. Polígonos de UCs — WFS INDE/ICMBio + CNUC/MMA — **ACESSÍVEL, TESTADO**
- WFS 2.0 `geoservicos.inde.gov.br/geoserver/ICMBio/ows`, camada
  `limiteucsfederais_a`, com `CQL_FILTER` por `nomeuc` e saída GeoJSON.
  **Teste real:** 2 UCs de Trindade recuperadas (44 KB), geometria validada.
- Camadas irmãs valiosas: `autos_infracao_icmbio`, `embargos_icmbio`
  (**fiscalização georreferenciada**), `canie_*` (CANIE).
- CNUC (dados.mma.gov.br): CSV cadastral + shapefiles semestrais 2024–2026
  (inclui capacidade de gestão — insumo para H7).

### 3. Seguro-Defeso — Portal da Transparência/CGU — **ACESSÍVEL, TESTADO**
- Download aberto mensal `.../download-de-dados/seguro-defeso/YYYYMM` →
  ZIP ~8,4 MB. **Baixado e inspecionado 202401**: MICRODADOS individuais —
  mês de referência, UF, município SIAFI, CPF mascarado, **NIS**, **RGP**,
  nome, valor da parcela (R$ 1.412,00 em 2024 = salário mínimo).
- Permite: painel município×mês de pagamentos E spells individuais por RGP
  (elegibilidade/tempestividade). Dado pessoal público — agregar para
  publicação. Falta testar: profundidade histórica da série.

### 4. Esforço pesqueiro — Global Fishing Watch API v3 — **TOKEN PENDENTE** (†)
- Serviço ativo (401 sem autenticação). Token gratuito = ação do pesquisador
  (conta em globalfishingwatch.org/our-apis; salvar em `.Renviron`).
- Esforço APARENTE (modelo sobre AIS): frota <15 m sub-representada — a pesca
  artesanal NÃO é observada por esta fonte; espécie não identificável;
  cobertura satelital variável (controlar).
- Cliente R `gfwr` fora do CRAN (†) — instalar do GitHub com pin no renv.

### 5. Ambiente — NOAA OISST v2.1 — **ACESSÍVEL** (†)
- SST 0,25° diária sem autenticação (NCEI HTTPS/PSL OPeNDAP OK; ERDDAP
  instável). Clorofila: Copernicus exige conta gratuita (não testado além do
  portal †).

### 6. Território — IBGE — **ACESSÍVEL** (†)
- APIs de localidades e malhas OK; `geobr` no CRAN.

## Secundários — condicionados

| Fonte | Status 2026-09-03 | Observação |
|---|---|---|
| Autos de infração IBAMA (dados abertos) | não testado | complementa WFS ICMBio já acessível |
| MPA/PesqBrasil (RGP, estatísticas) | não testado | RGP cruza com Seguro-Defeso |
| RAIS / Novo CAGED (CNAE 03) | não testado | só emprego formal; outcome municipal |
| Preços de pescado | **nenhuma série nacional verificada** | não usar até localizar fonte real |
| Luzes noturnas / VIIRS boat detection | não testado | proxy p/ pesca noturna (lula, sardinha) |
| Captura/desembarque | não testado | estatística nacional descontinuada ~2011; programas estaduais (PMAP-SP, UNIVALI-SC) fragmentados |
| DOU/INLABS (bulk XML) | página aberta; INLABS exige conta gratuita | necessário p/ histórico de normas |

## Bloqueios ativos

1. **GFW_TOKEN ausente** — administrativo; nenhum dado de esforço real até o
   pesquisador criar a conta (aviso: sem isso a parte causal não anda).
2. `www.ibama.gov.br` clássico 403 para curl — contornado via gov.br.
3. IN 189/2008: link oficial 404 — contornável via DOU/INLABS.
4. Sem série nacional de desembarque — limitação estrutural, moldará as
   claims do artigo (esforço, não estoque).
