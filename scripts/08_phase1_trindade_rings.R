# Background Job — FASE 1, caso Trindade: anéis geodésicos de leakage,
# modelo por zona e decomposição (protocolo, seção 7). Autorizado em D1
# (2026-09-10). Resultados são de FASE 1 (pré-registro dos estimandos em
# docs/estimand_table.md) — ainda sem correção de cobertura AIS nem controles
# ambientais, que entram nos passos seguintes.
suppressPackageStartupMessages({ library(data.table); library(sf); library(fixest) })
source("R/01_config.R"); source("R/10_build_spatial_rules.R")
source("R/11_build_treatment.R"); source("R/19_spillovers.R")
cfg <- load_config()
dir.create("outputs/models", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/tables", showWarnings = FALSE, recursive = TRUE)

mpa   <- load_mpa_polygons()
pilot <- fread("data/interim/pilot_panel_trindade.csv")
cells <- unique(pilot[, .(cell_lon, cell_lat)])
zones <- build_cell_zones(cells, mpa, rings_km = c(10, 25, 50, 100))
cat("Células por zona:\n"); print(zones[, .N, by = zone][order(zone)])

panel <- build_treatment_panel(pilot, zones, cfg$pilot_case$treatment_date)
fwrite(panel, "data/processed/panel_trindade_phase1.csv")
cat("Painel:", nrow(panel), "linhas |", uniqueN(panel$cell), "células |",
    uniqueN(panel$ym), "meses\n")

# ---- modelo por zona (intensivo e extensivo) ----
m_ihs <- run_leakage_model(panel, "ihs_hours")
m_ext <- run_leakage_model(panel, "presence")
saveRDS(list(ihs = m_ihs, presence = m_ext), "outputs/models/leakage_trindade_phase1.rds")
etable(m_ihs, m_ext, file = "outputs/tables/leakage_trindade_phase1.tex", replace = TRUE,
       title = "Trindade/Martim Vaz MPA creation (Decree 9,312/2018): effects by distance ring, control = >100 km. Phase-1 estimates, no AIS-coverage correction yet.")
print(etable(m_ihs, m_ext))

# ---- decomposição ----
dec <- leakage_decomposition(panel)
fwrite(dec$table, "outputs/tables/leakage_decomposition_trindade.csv")
cat("\nDecomposição (horas/mês, contrafactual = tendência do controle; crescimento do controle =",
    round(dec$control_growth, 3), "):\n")
print(dec$table[, .(zone, n_cells, hours_pre = round(hours_pre, 1), hours_pos = round(hours_pos, 1),
                    change_vs_control = round(change_vs_control, 1), pct = round(pct_vs_control, 1))])
cat(sprintf("\n  dentro (MONA+APA): %+.1f h/mês\n  anéis 0-100 km:    %+.1f h/mês\n  LÍQUIDO:           %+.1f h/mês\n",
            dec$inside_change, dec$rings_change, dec$net_change))
