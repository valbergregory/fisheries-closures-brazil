# Background Job — FASE 1: synthetic DiD por zona (Trindade), trimestral.
suppressPackageStartupMessages({ library(data.table); library(synthdid) })
source("R/18_synthetic_did.R")
panel <- fread("data/processed/panel_trindade_phase1.csv")
res <- list()
for (z in c("mona", "apa", "ring_0_10")) {
  cat("== zona", z, "==\n")
  r <- run_synthetic_did(panel, zone_treated = z, n_placebo = 50)
  cat(sprintf("  SDID = %+.4f (SE placebo %.4f) | SC = %+.4f | DiD = %+.4f | N1=%d N0=%d T0=%d T1=%d\n",
              r$sdid, r$se_sdid, r$sc, r$did, r$N1, r$N0, r$T0, r$T1))
  res[[z]] <- r
  png(sprintf("outputs/figures/synthdid_%s_trindade.png", z), width = 1100, height = 520, res = 130)
  print(plot(r$estimate_obj) + ggplot2::ggtitle(sprintf("Synthetic DiD — zona %s vs. doadores >100 km (trimestral, ihs horas)", z)))
  dev.off()
}
saveRDS(res, "outputs/models/synthdid_trindade_phase1.rds")
tab <- rbindlist(lapply(res, function(r) data.table(zone = r$zone, sdid = r$sdid, se_placebo = r$se_sdid,
                                                    t = r$sdid / r$se_sdid, sc = r$sc, did = r$did,
                                                    N1 = r$N1, N0 = r$N0, T0 = r$T0, T1 = r$T1)))
fwrite(tab, "outputs/tables/synthdid_trindade_phase1.csv"); print(tab)
