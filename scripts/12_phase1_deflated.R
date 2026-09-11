# Background Job — FASE 1: pesca DEFLACIONADA pela cobertura exógena.
# d = ihs(pesca) - ihs(cargo): esforço observado relativo à detecção de navios
# comerciais na mesma célula-mês (≈ log-razão). Event study de d por zona =
# diferença dos event studies (pesca menos cargo) — o artefato de detecção
# comum às duas séries cancela. Também: razão direta pesca/cargo e Conley.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
p <- fread("data/processed/panel_trindade_phase1.csv")
p[, d_cargo := ihs_hours - ihs_cargo]; p[, d_nonf := ihs_hours - ihs_nonfish]
p[, ratio_cargo := fifelse(cargo_hours > 0, fishing_hours / cargo_hours, NA_real_)]
res <- list(); fits <- list()
for (z in c("mona", "apa", "ring_0_10", "ring_10_25", "ring_25_50", "ring_50_100")) {
  sub <- p[zone %in% c(z, "control")]; sub[, tz := as.integer(zone == z)]
  specs <- list(d_cargo = d_cargo ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month,
                d_nonf  = d_nonf  ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month,
                ratio   = ratio_cargo ~ i(rel_y, tz, ref = -1) | cell + ym + tz^month)
  for (s in names(specs)) {
    f <- feols(specs[[s]], data = sub, cluster = ~cell); if (s == "d_cargo") fits[[z]] <- f
    ct <- coeftable(f); w <- wald(f, keep = "rel_y::-", print = FALSE)
    nm <- grep("rel_y", rownames(ct), value = TRUE)
    rq <- as.integer(gsub(":tz", "", gsub("rel_y::", "", nm, fixed = TRUE), fixed = TRUE)); est <- ct[nm, 1]; se <- ct[nm, 2]
    res[[length(res) + 1]] <- data.table(zone = z, spec = s, wald_leads_p = signif(w$p, 3),
      l2014 = round(est[rq == -4], 3), l2015 = round(est[rq == -3], 3), l2016 = round(est[rq == -2], 3),
      p2018 = round(est[rq == 0], 3), p2019 = round(est[rq == 1], 3), p2020 = round(est[rq == 2], 3),
      se_post = round(mean(se[rq >= 0]), 3))
  }
}
tab <- rbindlist(res); options(width = 160); print(tab, nrows = 40)
fwrite(tab, "outputs/tables/deflated_eventstudy_trindade.csv")
png("outputs/figures/eventstudy_deflated_trindade.png", width = 2000, height = 800, res = 130)
par(mfrow = c(2, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
for (z in names(fits)) iplot(fits[[z]], main = paste("zona:", z), xlab = "ano relativo (0 = 2018)", ylab = "ihs(pesca) - ihs(cargo)")
mtext("Trindade — pesca deflacionada pela detecção de cargueiros (cobertura exógena); ref = 2017", outer = TRUE, cex = 0.9)
dev.off()
# estático deflacionado, cluster célula e Conley 200 km
m_d  <- feols(d_cargo ~ i(zone, post, ref = "control") | cell + ym + zone^month, data = p, cluster = ~cell)
m_dc <- feols(d_cargo ~ i(zone, post, ref = "control") | cell + ym + zone^month, data = p,
              vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
print(etable(m_d, m_dc, headers = c("cluster célula", "Conley 200 km")))
etable(m_d, m_dc, file = "outputs/tables/static_deflated_trindade.tex", replace = TRUE, headers = c("cluster cell", "Conley 200km"))
saveRDS(list(cluster = m_d, conley = m_dc, es = fits), "outputs/models/deflated_trindade_phase1.rds")
