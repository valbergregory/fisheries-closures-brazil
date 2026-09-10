# Background Job — FASE 1: diagnóstico e correção de cobertura AIS (D13).
# (1) placebo: event study da PRESENÇA (todas as embarcações) — se reproduz a
#     pré-tendência da pesca, a causa é cobertura/tráfego, não comportamento;
# (2) outcomes corrigidos: fração pescando (fishing/presence) e ihs(pesca)
#     controlando por ihs(presença).
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/01_config.R"); source("R/10_build_spatial_rules.R"); source("R/11_build_treatment.R")
cfg <- load_config()
pilot <- fread("data/interim/pilot_panel_trindade.csv")
stopifnot("presence_hours" %in% names(pilot))
mpa <- load_mpa_polygons(); zones <- build_cell_zones(unique(pilot[, .(cell_lon, cell_lat)]), mpa)
p <- build_treatment_panel(pilot, zones, cfg$pilot_case$treatment_date)
p[, presence_hours := as.numeric(presence_hours)][is.na(presence_hours), presence_hours := 0]
p[, ihs_hours := asinh(fishing_hours)]; p[, ihs_pres := asinh(presence_hours)]
p[, fish_share := fifelse(presence_hours > 0, pmin(fishing_hours / presence_hours, 1), 0)]
p[, rel_y := year - 2018L]
fwrite(p, "data/processed/panel_trindade_phase1.csv")
cat("cobertura: presença média h/célula-mês por zona e ano\n")
print(dcast(p[, .(pres = round(mean(presence_hours), 2)), by = .(zone, year)], zone ~ year, value.var = "pres"))

res <- list()
for (z in c("mona", "apa", "ring_0_10")) {
  sub <- p[zone %in% c(z, "control")]; sub[, tz := as.integer(zone == z)]
  specs <- list(
    placebo_presence = ihs_pres  ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month,
    fish_share       = fish_share ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month,
    ihs_ctrl_pres    = ihs_hours ~ i(rel_y, tz, ref = -1) + ihs_pres | cell + ym + tz^month
  )
  for (s in names(specs)) {
    f <- feols(specs[[s]], data = sub, cluster = ~cell)
    ct <- coeftable(f); w <- wald(f, keep = "rel_y::-", print = FALSE)
    rq <- as.integer(gsub(":tz", "", gsub("rel_y::", "", grep("rel_y", rownames(ct), value = TRUE), fixed = TRUE), fixed = TRUE))
    est <- ct[grep("rel_y", rownames(ct)), 1]
    res[[length(res) + 1]] <- data.table(zone = z, spec = s, wald_leads_p = signif(w$p, 3),
      lead_2014 = round(est[rq == -4], 3), lead_2015 = round(est[rq == -3], 3), lead_2016 = round(est[rq == -2], 3),
      post_2018 = round(est[rq == 0], 3), post_2019 = round(est[rq == 1], 3), post_2020 = round(est[rq == 2], 3))
  }
}
tab <- rbindlist(res); print(tab)
fwrite(tab, "outputs/tables/coverage_diagnostics_trindade.csv")
