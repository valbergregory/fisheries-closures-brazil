# Background Job — A2: synthetic DiD sobre a frota com AIS pré-designação.
suppressPackageStartupMessages({ library(data.table); library(synthdid) })
source("R/18_synthetic_did.R")
p <- fread("data/processed/panel_trindade_phase1.csv")
p[, fishing_hours := as.numeric(fishing_hours_preais)][is.na(fishing_hours), fishing_hours := 0]
res <- list()
for (z in c("mona", "apa", "ring_0_10", "ring_10_25")) {
  r <- run_synthetic_did(p, zone_treated = z, n_placebo = 100)
  cat(sprintf("%-10s SDID = %+.4f (SE %.4f, t=%.2f) | SC = %+.4f | DiD = %+.4f | N1=%d\n", z, r$sdid, r$se_sdid, r$sdid/r$se_sdid, r$sc, r$did, r$N1))
  res[[z]] <- r
  png(sprintf("outputs/figures/synthdid_preais_%s.png", z), width = 1100, height = 520, res = 130)
  print(plot(r$estimate_obj) + ggplot2::ggtitle(sprintf("SDID (frota pré-AIS) — zona %s", z))); dev.off()
}
tab <- rbindlist(lapply(res, function(r) data.table(zone = r$zone, sdid = r$sdid, se = r$se_sdid, t = r$sdid/r$se_sdid, sc = r$sc, did = r$did, N1 = r$N1)))
fwrite(tab, "outputs/tables/synthdid_preais_trindade.csv"); saveRDS(res, "outputs/models/synthdid_preais_trindade.rds")
