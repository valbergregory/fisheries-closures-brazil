# Background Job — FASE 1: PPML (Poisson) com detecção de cargueiros como
# exposição. Lida com zeros, é invariante à escala e a elasticidade da
# exposição é estimada (não imposta em 1). Amostra: célula-mês com cargo>0.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
p <- fread("data/processed/panel_trindade_phase1.csv")[cargo_hours > 0]
p[, log_cargo := log(cargo_hours)]; p[, log_nonf := log(pmax(nonfish_hours, 1e-6))]
res <- list(); fits <- list()
for (z in c("mona", "apa", "ring_0_10", "ring_10_25", "ring_25_50", "ring_50_100")) {
  sub <- p[zone %in% c(z, "control")]; sub[, tz := as.integer(zone == z)]
  for (s in c("ppml_cargo", "ppml_offset1")) {
    f <- if (s == "ppml_cargo")
      fepois(fishing_hours ~ i(rel_y, tz, ref = -1) + log_cargo | cell + ym + tz^month, data = sub, cluster = ~cell)
    else fepois(fishing_hours ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month, offset = ~log_cargo, data = sub, cluster = ~cell)
    if (s == "ppml_cargo") fits[[z]] <- f
    ct <- coeftable(f); w <- wald(f, keep = "rel_y::-", print = FALSE)
    nm <- grep("rel_y", rownames(ct), value = TRUE)
    rq <- as.integer(gsub(":tz", "", gsub("rel_y::", "", nm, fixed = TRUE), fixed = TRUE)); est <- ct[nm, 1]; se <- ct[nm, 2]
    res[[length(res) + 1]] <- data.table(zone = z, spec = s, wald_leads_p = signif(w$p, 3),
      l2014 = round(est[rq == -4], 3), l2015 = round(est[rq == -3], 3), l2016 = round(est[rq == -2], 3),
      p2018 = round(est[rq == 0], 3), p2019 = round(est[rq == 1], 3), p2020 = round(est[rq == 2], 3),
      se_post = round(mean(se[rq >= 0]), 3), elast_cargo = if (s == "ppml_cargo") round(ct["log_cargo", 1], 3) else 1, n = nobs(f))
  }
}
tab <- rbindlist(res); options(width = 170); print(tab, nrows = 40)
fwrite(tab, "outputs/tables/ppml_eventstudy_trindade.csv")
png("outputs/figures/eventstudy_ppml_trindade.png", width = 2000, height = 800, res = 130)
par(mfrow = c(2, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
for (z in names(fits)) iplot(fits[[z]], main = paste("zona:", z), xlab = "ano relativo (0 = 2018)", ylab = "log-efeito PPML")
mtext("Trindade — PPML das horas de pesca com log(detecção de cargueiros) como exposição; ref = 2017", outer = TRUE, cex = 0.9)
dev.off()
m_s <- fepois(fishing_hours ~ i(zone, post, ref = "control") + log_cargo | cell + ym + zone^month, data = p, cluster = ~cell)
m_c <- fepois(fishing_hours ~ i(zone, post, ref = "control") + log_cargo | cell + ym + zone^month, data = p,
              vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
print(etable(m_s, m_c, headers = c("cluster célula", "Conley 200 km")))
etable(m_s, m_c, file = "outputs/tables/static_ppml_trindade.tex", replace = TRUE, headers = c("cluster cell", "Conley 200km"))
saveRDS(list(cluster = m_s, conley = m_c, es = fits), "outputs/models/ppml_trindade_phase1.rds")
