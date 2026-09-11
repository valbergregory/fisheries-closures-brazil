# Background Job — FASE 1: identificação com cobertura EXÓGENA (não-pesqueiros).
# (1) placebo: event study de ihs(cargo_hours) por zona — mede se a detecção
#     AIS de navios COMERCIAIS tem a mesma pré-tendência da pesca;
# (2) outcomes corrigidos: ihs(pesca) com ihs(cargo) e ihs(nonfish) como
#     controles; taxa pesca/nonfish; (3) TWFE estático e SDID com correção.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/01_config.R"); source("R/10_build_spatial_rules.R"); source("R/11_build_treatment.R")
source("R/18_synthetic_did.R")
cfg <- load_config()
pilot <- fread("data/interim/pilot_panel_trindade.csv")
stopifnot(all(c("cargo_hours", "nonfish_hours") %in% names(pilot)))
mpa <- load_mpa_polygons(); zones <- build_cell_zones(unique(pilot[, .(cell_lon, cell_lat)]), mpa)
p <- build_treatment_panel(pilot, zones, cfg$pilot_case$treatment_date)
for (v in c("presence_hours", "cargo_hours", "passenger_hours", "nonfish_hours", "fishing_pres", "n_vessels_nonfish"))
  p[, (v) := fifelse(is.na(as.numeric(get(v))), 0, as.numeric(get(v)))]
p[, `:=`(ihs_hours = asinh(fishing_hours), ihs_cargo = asinh(cargo_hours),
         ihs_nonfish = asinh(nonfish_hours), rel_y = year - 2018L)]
p[, fish_per_nonfish := fifelse(nonfish_hours > 0, fishing_hours / nonfish_hours, NA_real_)]
fwrite(p, "data/processed/panel_trindade_phase1.csv")

cat("cobertura EXÓGENA (cargo h/célula-mês) por zona e ano:\n")
print(dcast(p[, .(v = round(mean(cargo_hours), 2)), by = .(zone, year)], zone ~ year, value.var = "v"))
cat("\nnão-pesqueiros (h/célula-mês):\n")
print(dcast(p[, .(v = round(mean(nonfish_hours), 2)), by = .(zone, year)], zone ~ year, value.var = "v"))

res <- list()
for (z in c("mona", "apa", "ring_0_10", "ring_10_25", "ring_25_50", "ring_50_100")) {
  sub <- p[zone %in% c(z, "control")]; sub[, tz := as.integer(zone == z)]
  specs <- list(
    placebo_cargo   = ihs_cargo   ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month,
    placebo_nonfish = ihs_nonfish ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month,
    fish_ctrl_cargo = ihs_hours   ~ i(rel_y, tz, ref = -1) + ihs_cargo | cell + ym + tz^month,
    fish_ctrl_nonf  = ihs_hours   ~ i(rel_y, tz, ref = -1) + ihs_nonfish | cell + ym + tz^month
  )
  for (s in names(specs)) {
    f <- feols(specs[[s]], data = sub, cluster = ~cell)
    ct <- coeftable(f); w <- wald(f, keep = "rel_y::-", print = FALSE)
    nm <- grep("rel_y", rownames(ct), value = TRUE)
    rq <- as.integer(gsub(":tz", "", gsub("rel_y::", "", nm, fixed = TRUE), fixed = TRUE)); est <- ct[nm, 1]
    res[[length(res) + 1]] <- data.table(zone = z, spec = s, wald_leads_p = signif(w$p, 3),
      l2014 = round(est[rq == -4], 3), l2015 = round(est[rq == -3], 3), l2016 = round(est[rq == -2], 3),
      p2018 = round(est[rq == 0], 3), p2019 = round(est[rq == 1], 3), p2020 = round(est[rq == 2], 3))
  }
}
tab <- rbindlist(res); print(tab, nrows = 40)
fwrite(tab, "outputs/tables/exog_coverage_eventstudy_trindade.csv")

# estático por zona com controle de cobertura exógena
m1 <- feols(ihs_hours ~ i(zone, post, ref = "control") | cell + ym + zone^month, data = p, cluster = ~cell)
m2 <- feols(ihs_hours ~ i(zone, post, ref = "control") + ihs_cargo | cell + ym + zone^month, data = p, cluster = ~cell)
m3 <- feols(ihs_hours ~ i(zone, post, ref = "control") + ihs_nonfish | cell + ym + zone^month, data = p, cluster = ~cell)
m4 <- feols(ihs_hours ~ i(zone, post, ref = "control") + ihs_nonfish | cell + ym + zone^month, data = p, vcov = conley(200, distance = "spherical"))
print(etable(m1, m2, m3, m4, headers = c("sem controle", "+cargo", "+nonfish", "+nonfish, Conley 200km")))
etable(m1, m2, m3, m4, file = "outputs/tables/static_exog_coverage_trindade.tex", replace = TRUE,
       headers = c("none", "+cargo", "+nonfish", "+nonfish Conley"))
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4), "outputs/models/static_exog_coverage_trindade.rds")
