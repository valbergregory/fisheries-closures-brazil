# Do Fishing Closures Protect Fish or Displace Fishing?

Research compendium do working paper:

> **Do Fishing Closures Protect Fish or Displace Fishing? Causal Evidence
> from Brazil's Seasonal Bans and Marine Protected Areas**
> (alternativas: *Do Fishing Restrictions Rebuild Stocks and Incomes? Spatial
> Causal Evidence from Brazil*; versão SI: *A Machine-Readable Fisheries
> Regulation Information System: Evaluating Compliance and Spatial
> Displacement in Brazil*)

Infraestrutura R-first, auditável e reproduzível, que transforma normas
pesqueiras brasileiras (defesos, áreas marinhas protegidas) em regras
legíveis por máquina — **Fisheries Regulation Knowledge Base and Spatial
Compliance Observatory** — e as cruza com esforço pesqueiro (Global Fishing
Watch/AIS), fiscalização, Seguro-Defeso e condições ambientais para estimar
efeitos causais e leakage espacial/temporal.

**Status (2026-09-03): primeira entrega** — auditoria de ambiente, estrutura,
protocolo, inventários, 3 normas reais recuperadas, 1 regra estruturada
(validação humana pendente), polígonos de UC testados via WFS, piloto
diagnóstico Trindade/Martim Vaz, relatório de viabilidade.
**Nenhum download de universo completo e nenhuma estimação definitiva.**
Ver [docs/feasibility_report.md](docs/feasibility_report.md).

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `config/` | Configuração, inventário de fontes, esquema do registro regulatório |
| `R/` | Funções do pipeline (chamadas por `_targets.R`) |
| `python/` | Extração de texto legal, validação de esquema, trajetórias (ambiente isolado) |
| `sql/` | DDL DuckDB: registro de regras, exposição espacial, painel |
| `scripts/` | Executáveis (Console / RStudio Background Jobs / Terminal) |
| `data/legal/` | Normas oficiais baixadas (PDF fora do Git; texto+checksums versionados) |
| `data/raw` … `processed/` | Dados (fora do Git) |
| `data/metadata/` | Checksums, linhagem |
| `outputs/policies/` | Regras estruturadas (JSON validado contra esquema) |
| `outputs/diagnostics/` | Mapas e relatórios do piloto |
| `docs/` | Protocolo, inventários, identificação, estimandos, decisões, viabilidade |
| `article/` | Manuscrito Quarto (EN) |
| `app/` | Shiny (Observatório — após viabilidade aprovada) |
| `tests/` | testthat (R) + pytest (Python) |

## Como reproduzir (estado atual)

```r
# RStudio, projeto aberto (project.Rproj):
source("scripts/00_check_environment.R")   # auditoria do ambiente
# renv::init() na primeira sessão (ver docs/reproducibility_guide.md)
```

```bash
# Terminal:
python python/validate_policy_schema.py "outputs/policies/*.json"
python python/feasibility_pilot.py
```

O pipeline completo (`targets::tar_make()`) só roda após aprovação do
relatório de viabilidade pelo pesquisador.

## Credenciais

Tokens ficam fora do Git, em `.Renviron` na raiz (já no `.gitignore`):

```
GFW_TOKEN=<token gratuito da API do Global Fishing Watch>
```

Criar conta em <https://globalfishingwatch.org/our-apis/>.

## Regras de ouro do projeto

1. Nenhuma norma, data, espécie, polígono ou resultado é inventado — tudo
   rastreável a fonte oficial com checksum.
2. Toda regra estruturada passa por validação humana antes de uso científico
   (`validation.human_validated`).
3. AIS **não** representa a pesca artesanal — limitação declarada em toda
   análise.
4. Redução de esforço observado ≠ recuperação de estoque.
5. Resultados científicos não dependem de objetos manuais no Global
   Environment.

## License

Code: MIT ([LICENSE](LICENSE)). Text, documentation and data: see [LICENSING.md](LICENSING.md).
