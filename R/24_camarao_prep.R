# 24_camarao_prep.R — preparação canônica do painel do camarão (D3/D18).
# Uso: p <- prep_camarao()  |  p <- prep_camarao(radius_km = 50)
prep_camarao <- function(file = "data/processed/panel_camarao.csv",
                         sst_file = "data/interim/sst_camarao_monthly.csv",
                         radius_km = 100, drop_inland = TRUE) {
  p <- data.table::fread(file)
  stopifnot(all(c("coast_km", "uf", "on_land") %in% names(p)))
  if (drop_inland) p <- p[on_land == FALSE]
  if (!is.null(radius_km)) p <- p[coast_km <= radius_km]
  sst <- data.table::fread(sst_file)
  p <- merge(p, sst[, .(cell_lon, cell_lat, year, month, sst)],
             by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
  p[, `:=`(cell = paste(cell_lon, cell_lat), post = as.integer(year >= 2023),
           ym = year * 100L + month,
           ihs_all = asinh(trawl_hours), ihs_pre = asinh(trawl_hours_prefleet),
           ihs_pres = asinh(presence_hours), ihs_other = asinh(other_hours))]
  if ("cargo_hours" %in% names(p)) p[, ihs_cargo := asinh(as.numeric(cargo_hours))]
  if ("nonfish_hours" %in% names(p)) p[, ihs_nonf := asinh(as.numeric(nonfish_hours))]
  # status do mês sob a reforma (Portaria SAP/MAPA 656/2022; regime anterior mar-mai)
  p[, status := data.table::fcase(
      month == 2, "new_closed",       # livre -> proibido
      month == 5, "new_open",         # proibido -> livre
      month %in% 3:4, "closed_both",  # proibido nos dois regimes
      month == 1, "mixed_jan",        # 28-31/jan proibido só no regime novo
      default = "open_both")]
  p[, status := factor(status, levels = c("open_both", "new_closed", "new_open", "closed_both", "mixed_jan"))]
  p[]
}
