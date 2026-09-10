# 15_event_study.R — dinâmica por zona, trimestres relativos ao tratamento.
# Trimestre 0 = 2018Q1 (Decreto 9.312 de 19/03/2018); referência = 2017Q4.

run_event_study <- function(panel, zones_of_interest = c("mona", "apa", "ring_0_10"),
                            ref_quarter = -1, outcome = "ihs_hours") {
  p <- data.table::copy(panel)
  p[, ihs_hours := asinh(fishing_hours)]
  p[, presence := as.integer(fishing_hours > 0)]
  p[, rel_q := (year - 2018L) * 4L + (month - 1L) %/% 3L]
  fits <- lapply(zones_of_interest, function(z) {
    sub <- p[zone %in% c(z, "control")]
    sub[, tz := as.integer(zone == z)]
    f <- stats::as.formula(paste0(outcome, " ~ i(rel_q, tz, ref = ", ref_quarter, ") | cell + ym"))
    fixest::feols(f, data = sub, cluster = ~cell)
  })
  names(fits) <- zones_of_interest
  fits
}

plot_event_study <- function(fits, file, title) {
  grDevices::png(file, width = 1600, height = 520, res = 130)
  graphics::par(mfrow = c(1, length(fits)), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
  for (z in names(fits)) {
    fixest::iplot(fits[[z]], main = paste0("zona: ", z),
                  xlab = "trimestre relativo (0 = 2018Q1)", ylab = "efeito vs. controle (ihs horas)")
  }
  graphics::mtext(title, side = 3, outer = TRUE, cex = 0.85)
  grDevices::dev.off()
}
