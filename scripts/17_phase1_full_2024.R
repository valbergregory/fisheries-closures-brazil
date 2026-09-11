# Background Job — A3+A5: painel 2014-2024, frota pré-AIS, controles SST,
# event study de horizonte longo e estático com Conley.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/01_config.R"); source("R/10_build_spatial_rules.R"); source("R/11_build_treatment.R")
cfg <- load_config(); pilot <- fread("data/interim/pilot_panel_trindade.csv")
mpa <- load_mpa_polygons(); zones <- build_cell_zones(unique(pilot[, .(cell_lon, cell_lat)]), mpa)
p <- build_treatment_panel(pilot, zones, cfg$pilot_case$treatment_date)
sst <- fread("data/interim/sst_trindade_monthly.csv")
p <- merge(p, sst[, .(cell_lon, cell_lat, year, month, sst, sst_anom)], by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
for (v in c("fishing_hours_preais", "cargo_hours", "nonfish_hours")) p[, (v) := fifelse(is.na(as.numeric(get(v))), 0, as.numeric(get(v)))]
p[, `:=`(y = fishing_hours_preais, ihs_y = asinh(fishing_hours_preais), ihs_all = asinh(fishing_hours), rel_y = year - 2018L)]
fwrite(p, "data/processed/panel_trindade_phase1.csv")
cat("painel:", nrow(p), "| anos:", paste(range(p$year), collapse = "-"), "| SST NA:", sum(is.na(p$sst)), "\n")

res <- list(); fits <- list()
for (z in c("mona", "apa", "ring_0_10", "ring_10_25", "ring_25_50", "ring_50_100")) {
  sub <- p[zone %in% c(z, "control")]; sub[, tz := as.integer(zone == z)]
  specs <- list(
    ihs_preais        = ihs_y ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month,
    ihs_preais_sst    = ihs_y ~ i(rel_y, tz, ref = -1) + sst + sst_anom | cell + ym + tz^month,
    ppml_preais_sst   = y ~ i(rel_y, tz, ref = -1) + sst + sst_anom | cell + ym + tz^month)
  for (s in names(specs)) {
    f <- if (grepl("ppml", s)) fepois(specs[[s]], data = sub, cluster = ~cell) else feols(specs[[s]], data = sub, cluster = ~cell)
    if (s == "ihs_preais_sst") fits[[z]] <- f
    ct <- coeftable(f); w <- wald(f, keep = "rel_y::-", print = FALSE)
    nm <- grep("rel_y", rownames(ct), value = TRUE)
    rq <- as.integer(gsub(":tz", "", gsub("rel_y::", "", nm, fixed = TRUE), fixed = TRUE)); est <- ct[nm, 1]
    row <- data.table(zone = z, spec = s, wald_leads_p = signif(w$p, 3))
    for (k in c(-4, -3, -2, 0:6)) row[, (paste0("y", ifelse(k < 0, paste0("m", -k), k))) := round(est[rq == k], 3)]
    row[, mean_post := round(mean(est[rq >= 0]), 3)]; row[, se_post := round(mean(ct[nm, 2][rq >= 0]), 3)]
    res[[length(res) + 1]] <- row
  }
}
tab <- rbindlist(res, fill = TRUE); options(width = 200); print(tab, nrows = 40)
fwrite(tab, "outputs/tables/eventstudy_2014_2024_preais_trindade.csv")
png("outputs/figures/eventstudy_2014_2024_preais_trindade.png", width = 2000, height = 800, res = 130)
par(mfrow = c(2, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
for (z in names(fits)) iplot(fits[[z]], main = paste("zona:", z), xlab = "ano relativo (0 = 2018)", ylab = "ihs horas (frota pré-AIS)")
mtext("Trindade 2014–2024 — frota com AIS pré-designação, controles SST, sazonalidade por zona; ref = 2017", outer = TRUE, cex = 0.9)
dev.off()
m1 <- feols(ihs_y ~ i(zone, post, ref = "control") + sst + sst_anom | cell + ym + zone^month, data = p, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
m2 <- fepois(y ~ i(zone, post, ref = "control") + sst + sst_anom | cell + ym + zone^month, data = p, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
m3 <- feols(ihs_all ~ i(zone, post, ref = "control") + sst + sst_anom | cell + ym + zone^month, data = p, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
print(etable(m1, m2, m3, headers = c("ihs pré-AIS", "PPML pré-AIS", "ihs toda a frota")))
etable(m1, m2, m3, file = "outputs/tables/static_2014_2024_trindade.tex", replace = TRUE, headers = c("ihs preAIS", "PPML preAIS", "ihs all"))
saveRDS(list(ihs = m1, ppml = m2, all = m3, es = fits), "outputs/models/full_2014_2024_trindade.rds")
