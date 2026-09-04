# 06_download_fishing_effort.R — esqueleto (primeira entrega 2026-09-03).
# Contrato de interface definido; corpo ativado por fase (ver _targets.R).

download_fishing_effort <- function(cfg) { tok <- Sys.getenv(cfg$credentials$gfw_token_env); if (!nzchar(tok)) stop('GFW_TOKEN ausente em .Renviron'); stop('Fase 1: gfwr::get_raster() janela piloto') }
