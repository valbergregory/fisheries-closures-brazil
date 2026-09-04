# Guia de reprodutibilidade

## Princípios

1. Tudo que entra em resultado científico nasce do pipeline `targets` — nada
   de objetos manuais no Global Environment.
2. Dado bruto é imutável (`data/raw/`, `data/legal/`) e fica fora do Git;
   checksums SHA-256 versionados em `data/metadata/`.
3. Seeds fixas (`config/config.yml: project.seed`).
4. Toda decisão discricionária vira entrada em `docs/decisions_log.md`.

## Ambientes

**R (principal):** R 4.4.3. Na primeira sessão RStudio:
```r
install.packages("renv")   # já instalado
renv::init(bare = TRUE)
renv::install(c("targets","tarchetypes","data.table","yaml","jsonlite",
                "digest","httr2","curl","fixest","did","modelsummary",
                "sf","terra","duckdb","arrow","rdrobust","rddensity",
                "ggplot2","patchwork","testthat"))
renv::snapshot()           # gera renv.lock (ainda não criado nesta entrega)
```
`renv.lock` e `uv.lock` **não** foram fabricados à mão nesta entrega — serão
gerados pelas próprias ferramentas para refletirem o ambiente real.

**Python (auxiliar):** 3.13.2 do sistema (pandas, matplotlib, pymupdf já
presentes). Se a camada crescer: instalar `uv`, `uv venv`, `uv add ...` a
partir do `pyproject.toml` (gera `uv.lock`).

## Execução (RStudio)

| Onde | O quê |
|---|---|
| Console | `scripts/00_check_environment.R`; verificações rápidas |
| Background Jobs | `scripts/01_test_policy_sources.R`, `02_test_data_access.R`, `03_run_feasibility.R`, `04_run_pipeline.R`, (fase 2) `05_run_models.R` |
| Terminal | git; `quarto render article/manuscript.qmd`; `python python/validate_policy_schema.py`; pytest; duckdb |

## Logs e linhagem

Background jobs gravam em `outputs/logs/` com timestamp. Downloads registram
URL, data de acesso e SHA-256. O registro regulatório referencia artigo e
parágrafo da norma para cada campo controverso.

## Credenciais e licenças

`.Renviron` (fora do Git): `GFW_TOKEN`. Licenças por fonte em
`config/data_sources.yml`; dados brutos não são redistribuídos; agregados
derivados de GFW respeitam CC BY-SA 4.0; microdados do Seguro-Defeso nunca
publicados desagregados (D9).

## Reconstrução do zero

1. clonar repo; 2. `renv::restore()`; 3. `.Renviron` com token; 4.
`scripts/01`–`03` (jobs); 5. `targets::tar_make()`; 6.
`quarto render article/`. Divergências esperadas: atualizações das fontes
vivas (WFS, CGU) — por isso as versões locais têm checksum e data de acesso.
