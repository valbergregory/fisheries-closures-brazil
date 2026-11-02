# Do Fishing Closures Protect Fish or Displace Fishing?

Research compendium do working paper *Do Fishing Closures Protect Fish or
Displace Fishing? Causal Evidence from Brazil's Seasonal Bans and Marine
Protected Areas*.

O repositório transforma normas pesqueiras brasileiras (defesos sazonais,
áreas marinhas protegidas, mandatos de rastreamento) em regras legíveis por
máquina e as cruza com esforço pesqueiro observado por AIS, Seguro-Defeso e
condições ambientais para estimar efeitos sobre o esforço e seu deslocamento
no espaço e no tempo.

**Pergunta de pesquisa.** Defesos sazonais e áreas marinhas protegidas
reduzem a pressão pesqueira total ou deslocam o esforço no espaço, no tempo e
entre espécies?

Casos estudados (ver `config/config.yml`):

- MONA/APA do Arquipélago de Trindade e Martim Vaz (Decreto 9.312/2018);
- defeso do camarão nas regiões Sudeste/Sul (Portaria SAP/MAPA 656/2022,
  mudança de calendário em 2023).

## Dados e fontes

Inventário completo, com licença, forma de acesso e limitações por fonte, em
`config/data_sources.yml` (versão narrativa em `docs/data_inventory.md`).

| Fonte | Órgão | Uso |
|---|---|---|
| Apparent fishing effort (AIS) — API v3 | Global Fishing Watch | esforço por célula × mês × arte × bandeira (2012–presente) |
| Tabela de defesos marinhos e PDFs das normas | IBAMA | catálogo jurídico (`config/policy_sources.yml`) |
| Texto oficial das normas | Imprensa Nacional (in.gov.br) e Planalto | corpus legal em `data/legal/` |
| Limites de UCs federais (WFS), autos de infração e embargos | ICMBio via INDE | polígonos das áreas protegidas; fiscalização |
| Cadastro Nacional de Unidades de Conservação | MMA | cadastro e shapefiles de UCs |
| Microdados do Seguro-Defeso | CGU — Portal da Transparência | agregado município × mês |
| OISST v2.1 (temperatura da superfície do mar) | NOAA | controle ambiental |
| Malhas municipais e linha de costa | IBGE | distância à costa |

Os textos legais em `data/legal/` são atos oficiais brasileiros (domínio
público) e estão versionados com SHA-256 em `data/metadata/`. Dados brutos
(`data/raw/`, `data/interim/`, `data/processed/`) ficam fora do Git.

## Estrutura do repositório

| Pasta | Conteúdo |
|---|---|
| `config/` | `config.yml` (casos, grade, janelas), `data_sources.yml`, `policy_sources.yml`, `observability_mandates.yml`, `empirical_designs.yml`, `policy_rule_schema.json` |
| `R/` | Funções do pipeline (configuração, registro regulatório, construção de painel, desenhos empíricos, figuras e tabelas) |
| `python/` | Download e extração de texto legal, validação do esquema de regras, construção dos painéis célula × mês e embarcação × zona × mês |
| `sql/` | DDL DuckDB (ver esquema abaixo) |
| `scripts/` | Executáveis numerados (verificação de ambiente, testes de acesso, pipeline, modelos, figuras e tabelas) |
| `_targets.R` | Orquestração com `targets` (chama os builders Python e os scripts R) |
| `data/legal/` | Normas oficiais (HTML/TXT); `corpus_defesos_marinhos/` com 26 normas de defeso marinho; `observability/` com mandatos de rastreamento |
| `data/metadata/` | Checksums SHA-256 dos arquivos legais e dos extratos do GFW |
| `outputs/policies/` | Regras estruturadas (JSON validado contra `config/policy_rule_schema.json`); `screening/` com a triagem do corpus |
| `outputs/tables/`, `outputs/figures/` | Tabelas e figuras geradas pelos scripts |
| `outputs/diagnostics/` | Mapas e relatórios do piloto |
| `docs/` | Protocolo de pesquisa, estratégia de identificação, tabela de estimandos, protocolo do registro regulatório, dicionário de dados, inventário de dados, registro de decisões, guia de reprodutibilidade |
| `app/` | Protótipo Shiny que lista o registro de regras |
| `tests/` | `testthat` (R) e `pytest` (Python) |

### Registro regulatório

Unidade: a **regra atômica** = espécie(s) × área × período × modalidade, com
vigência e exceções; uma norma gera uma ou mais regras. Esquema em
`config/policy_rule_schema.json`; protocolo em
`docs/policy_registry_protocol.md`. Cada regra traz o campo
`validation.human_validated`.

### Esquema DuckDB (`sql/`)

| Schema | Tabelas |
|---|---|
| `reg` | `rules` (regra atômica), `rule_species`, `norms` (norma, URL oficial, SHA-256) |
| `geo` | `cells` (centro, zona, distância à fronteira, profundidade, distância à costa), `cell_rule_exposure` (célula × regra × janela, anéis de distância) |
| `fx` | `panel_month` (célula × ano × mês: horas de pesca, embarcações, cobertura AIS, SST, tratamento) |
| `aud` | `exclusions` (exclusões documentadas da amostra) |

Dicionário das tabelas intermediárias em `docs/data_dictionary.md`.

## Como reproduzir

Ambiente R gerenciado por `renv` (`renv.lock`); Python 3.13 com `pyproject.toml`.

```r
# RStudio, projeto aberto (project.Rproj)
renv::restore()
source("scripts/00_check_environment.R")
targets::tar_make()            # ou: Rscript scripts/04_run_pipeline.R
```

```bash
python python/validate_policy_schema.py "outputs/policies/*.json"
pytest tests/python
```

Detalhes em `docs/reproducibility_guide.md`.

## Credenciais

`GFW_TOKEN` (API do Global Fishing Watch), em `.Renviron` na raiz do projeto,
fora do Git.

## Dados pessoais

Os microdados do Seguro-Defeso contêm dados pessoais tornados públicos
(nome, CPF mascarado, NIS, RGP). Eles ficam fora do Git e só são publicados
agregados por município × mês (decisão D9 em `docs/decisions_log.md`).

## Licença e citação

Código: MIT ([LICENSE](LICENSE)). Textos legais, documentação, figuras e
dados: ver [LICENSING.md](LICENSING.md); agregados derivados do Global
Fishing Watch seguem CC BY-SA 4.0.

Citação: ver [CITATION.cff](CITATION.cff).
