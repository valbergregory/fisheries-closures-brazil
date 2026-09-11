# Background Job — D14: modelos por zona com esforço SÓ da frota observável
# antes da designação (remove adoção de AIS). Mesmas especificações da fase 1.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/01_config.R"); source("R/10_build_spatial_rules.R"); source("R/11_build_treatment.R")
cfg <- load_config(); pilot <- fread("data/interim/pilot_panel_trindade.csv")
mpa <- load_mpa_polygons(); zones <- build_cell_zones(unique(pilot[, .(cell_lon, cell_lat)]), mpa)
p <- build_treatment_panel(pilot, zones, cfg$pilot_case$treatment_date)
p[, y := as.numeric(fishing_hours_preais)][is.na(y), y := 0]; p[, ihs_y := asinh(y)]; p[, rel_y := year - 2018L]
fwrite(p, "data/processed/panel_trindade_phase1.csv")
res <- list()
for (z in c("mona", "apa", "ring_0_10", "ring_10_25", "ring_25_50", "ring_50_100")) {
  sub <- p[zone %in% c(z, "control")]; sub[, tz := as.integer(zone == z)]
  f <- feols(ihs_y ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month, data = sub, cluster = ~cell)
  g <- fepois(y ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month, data = sub, cluster = ~cell)
  for (s in c("ihs", "ppml")) {
    m <- if (s == "ihs") f else g
    ct <- coeftable(m); w <- wald(m, keep = "rel_y::-", print = FALSE)
    nm <- grep("rel_y", rownames(ct), value = TRUE)
    rq <- as.integer(gsub(":tz", "", gsub("rel_y::", "", nm, fixed = TRUE), fixed = TRUE)); est <- ct[nm, 1]
    res[[length(res) + 1]] <- data.table(zone = z, spec = s, wald_leads_p = signif(w$p, 3),
      l2014 = round(est[rq == -4], 3), l2015 = round(est[rq == -3], 3), l2016 = round(est[rq == -2], 3),
      p2018 = round(est[rq == 0], 3), p2019 = round(est[rq == 1], 3), p2020 = round(est[rq == 2], 3), se_post = round(mean(ct[nm, 2][rq >= 0]), 3))
  }
}
tab <- rbindlist(res); options(width = 170); print(tab, nrows = 40)
fwrite(tab, "outputs/tables/preais_eventstudy_trindade.csv")
m1 <- feols(ihs_y ~ i(zone, post, ref = "control") | cell + ym + zone^month, data = p, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
m2 <- fepois(y ~ i(zone, post, ref = "control") | cell + ym + zone^month, data = p, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
print(etable(m1, m2, headers = c("ihs, Conley 200 km", "PPML, Conley 200 km")))
etable(m1, m2, file = "outputs/tables/static_preais_trindade.tex", replace = TRUE, headers = c("ihs Conley", "PPML Conley"))
saveRDS(list(ihs = m1, ppml = m2), "outputs/models/preais_trindade_phase1.rds")
