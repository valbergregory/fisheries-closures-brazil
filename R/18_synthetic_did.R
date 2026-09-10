# 18_synthetic_did.R — synthetic DiD (Arkhangelsky et al. 2021) por zona.
# Bloco de adoção simultânea (2018-03). Agregado a TRIMESTRES para reduzir o
# ruído mensal da pescaria pelágica. Doadores = células de controle (>100 km).

run_synthetic_did <- function(panel, zone_treated = "mona", donors = "control",
                              outcome = "ihs_hours", n_placebo = 50, seed = 20260903) {
  p <- data.table::as.data.table(panel)[zone %in% c(zone_treated, donors)]
  p[, ihs_hours := asinh(fishing_hours)]
  p[, quarter := (year - 2014L) * 4L + (month - 1L) %/% 3L + 1L]
  q <- p[, .(y = mean(get(outcome)), treated = as.integer(zone[1] == zone_treated),
             post = max(post)), by = .(cell, quarter)]
  # tratamento em bloco: trimestre >= 2018Q1 (índice 17) para as células tratadas
  q[, w := treated * as.integer(quarter >= 17L)]
  q <- q[order(cell, quarter)]
  setup <- synthdid::panel.matrices(as.data.frame(q[, .(cell, quarter, y, w)]),
                                    unit = "cell", time = "quarter", outcome = "y", treatment = "w")
  tau_sdid <- synthdid::synthdid_estimate(setup$Y, setup$N0, setup$T0)
  tau_sc   <- synthdid::sc_estimate(setup$Y, setup$N0, setup$T0)
  tau_did  <- synthdid::did_estimate(setup$Y, setup$N0, setup$T0)
  set.seed(seed)
  se_sdid <- sqrt(stats::vcov(tau_sdid, method = "placebo", replications = n_placebo))
  list(zone = zone_treated, sdid = as.numeric(tau_sdid), se_sdid = as.numeric(se_sdid),
       sc = as.numeric(tau_sc), did = as.numeric(tau_did),
       N0 = setup$N0, N1 = nrow(setup$Y) - setup$N0, T0 = setup$T0, T1 = ncol(setup$Y) - setup$T0,
       estimate_obj = tau_sdid)
}
