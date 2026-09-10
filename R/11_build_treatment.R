# 11_build_treatment.R — exposição célula × período.

build_treatment_panel <- function(panel, zones, treatment_date) {
  p <- data.table::as.data.table(panel)
  z <- zones[, .(cell_lon, cell_lat, zone, dist_mona_km, dist_apa_km)]
  p <- merge(p[, setdiff(names(p), c("zone", "dist_boundary_km")), with = FALSE],
             z, by = c("cell_lon", "cell_lat"), all.x = TRUE)
  stopifnot(!anyNA(p$zone))
  td <- as.Date(treatment_date)
  p[, ym := year * 100L + month]
  p[, post := as.integer(as.Date(sprintf("%d-%02d-01", year, month)) >=
                          as.Date(sprintf("%d-%02d-01", as.integer(format(td, "%Y")),
                                          as.integer(format(td, "%m")))))]
  p[, cell := paste(cell_lon, cell_lat)]
  p[, fishing_hours := as.numeric(fishing_hours)]
  p[is.na(fishing_hours), fishing_hours := 0]
  p[]
}
