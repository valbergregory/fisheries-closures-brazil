# 08_download_environment.R — SST (NOAA OISST v2.1, 0,25° diário) por
# célula-mês. Reaproveita os arquivos anuais globais já baixados pelo projeto
# irmão marine-fisheries-data-cube (data/raw/oisst_global/), sem novo download.
# Grade do painel (0,25°, centros em .125/.375/.625/.875) coincide com a do OISST.

oisst_monthly_for_grid <- function(cells, years, src_dir,
                                   out_file = "data/interim/sst_trindade_monthly.csv") {
  stopifnot(dir.exists(src_dir))
  lon360 <- function(x) ifelse(x < 0, x + 360, x)
  lons <- sort(unique(cells$cell_lon)); lats <- sort(unique(cells$cell_lat))
  out <- list()
  for (y in years) {
    f <- file.path(src_dir, sprintf("sst.day.mean.%d.nc", y))
    if (!file.exists(f)) { message("ausente: ", f); next }
    nc <- ncdf4::nc_open(f)
    lon_all <- as.numeric(ncdf4::ncvar_get(nc, "lon")); lat_all <- as.numeric(ncdf4::ncvar_get(nc, "lat"))
    tm <- as.Date(floor(as.numeric(ncdf4::ncvar_get(nc, "time"))), origin = "1800-01-01")
    il <- which(lon_all >= lon360(min(lons)) - 0.01 & lon_all <= lon360(max(lons)) + 0.01)
    ia <- which(lat_all >= min(lats) - 0.01 & lat_all <= max(lats) + 0.01)
    sst <- ncdf4::ncvar_get(nc, "sst", start = c(min(il), min(ia), 1), count = c(length(il), length(ia), -1))
    ncdf4::nc_close(nc)
    mon <- as.integer(format(tm, "%m"))
    for (m in 1:12) {
      sl <- sst[, , mon == m, drop = FALSE]
      mm <- apply(sl, c(1, 2), mean, na.rm = TRUE)
      g <- data.table::CJ(cell_lon = lon_all[il], cell_lat = lat_all[ia], sorted = FALSE)
      g[, sst := as.vector(mm)]; g[, cell_lon := ifelse(cell_lon > 180, cell_lon - 360, cell_lon)]
      g[, `:=`(year = y, month = m)]
      out[[length(out) + 1]] <- g
    }
    message("OISST ", y, " ok")
  }
  res <- data.table::rbindlist(out)[!is.nan(sst)]
  # anomalia = sst - climatologia mensal da célula (anos disponíveis)
  res[, sst_clim := mean(sst), by = .(cell_lon, cell_lat, month)]
  res[, sst_anom := sst - sst_clim]
  data.table::fwrite(res, out_file); res[]
}
