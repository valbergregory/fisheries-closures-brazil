# 19_spillovers.R — leakage: modelo por zona e decomposição (protocolo, seção 7).

# Efeitos por zona relativos ao controle (>último anel), FE célula + ano-mês.
run_leakage_model <- function(panel, outcome = "ihs_hours") {
  p <- data.table::copy(panel)
  p[, ihs_hours := asinh(fishing_hours)]
  p[, presence := as.integer(fishing_hours > 0)]
  f <- stats::as.formula(paste0(outcome, " ~ i(zone, post, ref = 'control') | cell + ym"))
  fixest::feols(f, data = p, cluster = ~cell)
}

# Decomposição contrafactual (DiD por zona, em horas TOTAIS):
#   mudança_z = (pós_z − pré_z) − pré_z × (pós_ctrl/pré_ctrl − 1)
# i.e., o que a zona mudou além do que teria mudado se seguisse o controle.
# Soma das zonas tratadas/anéis = mudança líquida atribuível. Respeita D13
# (o controle absorve a tendência comum de cobertura).
leakage_decomposition <- function(panel) {
  p <- data.table::as.data.table(panel)
  n_pre <- p[post == 0, data.table::uniqueN(ym)]
  n_pos <- p[post == 1, data.table::uniqueN(ym)]
  agg <- p[, .(hours_pre = sum(fishing_hours[post == 0]) / n_pre,
               hours_pos = sum(fishing_hours[post == 1]) / n_pos,
               n_cells = data.table::uniqueN(cell)), by = zone]
  ctrl_growth <- agg[zone == "control", hours_pos / hours_pre]
  agg[, counterfactual_pos := hours_pre * ctrl_growth]
  agg[, change_vs_control := hours_pos - counterfactual_pos]
  agg[, pct_vs_control := 100 * change_vs_control / counterfactual_pos]
  data.table::setorder(agg, zone)
  list(table = agg[], control_growth = ctrl_growth,
       net_change = agg[zone != "control", sum(change_vs_control)],
       inside_change = agg[zone %in% c("mona", "apa"), sum(change_vs_control)],
       rings_change = agg[grepl("^ring", zone), sum(change_vs_control)])
}
