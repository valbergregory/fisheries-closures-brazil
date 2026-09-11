# Background Job — A4: placebos geográficos e temporal para o efeito no anel 0-10 km.
# Geográfico: desloca APA+MONA em uma grade de (dlon, dlat), recomputa zonas,
# estima o coeficiente 'anel 0-10 km × pós' numa amostra que EXCLUI as células
# realmente tratadas (APA/MONA verdadeiras). Temporal: tratamento fictício em
# 2016-03 usando só 2014-2017.
suppressPackageStartupMessages({ library(data.table); library(sf); library(fixest) })
source("R/10_build_spatial_rules.R")
p <- fread("data/processed/panel_trindade_phase1.csv")
mpa <- load_mpa_polygons(); cells <- unique(p[, .(cell_lon, cell_lat)])
real_zone <- p[, .(zone = zone[1]), by = .(cell_lon, cell_lat)]
est_ring <- function(pan) {
  f <- feols(ihs_y ~ i(zone, post, ref = "control") + sst + sst_anom | cell + ym + zone^month, data = pan, cluster = ~cell)
  ct <- coeftable(f); ct["zone::ring_0_10:post", 1]
}
real <- est_ring(p); cat("efeito REAL anel 0-10 km:", round(real, 4), "\n")
shifts <- CJ(dx = seq(-2, 2, 0.5), dy = seq(-2, 2, 0.5))[!(dx == 0 & dy == 0)]
out <- list()
for (i in seq_len(nrow(shifts))) {
  sh <- mpa; st_geometry(sh) <- st_geometry(mpa) + c(shifts$dx[i], shifts$dy[i]); st_crs(sh) <- 4326
  z <- build_cell_zones(cells, sh)[, .(cell_lon, cell_lat, zone_pl = zone)]
  pan <- merge(p[, !"zone"], z, by = c("cell_lon", "cell_lat")); setnames(pan, "zone_pl", "zone")
  pan <- merge(pan, real_zone[, .(cell_lon, cell_lat, zone_real = zone)], by = c("cell_lon", "cell_lat"))
  pan <- pan[!zone_real %in% c("mona", "apa")]              # só oceano realmente não tratado
  n_ring <- pan[zone == "ring_0_10", uniqueN(cell)]
  if (n_ring < 15) next
  b <- tryCatch(est_ring(pan), error = function(e) NA_real_)
  out[[length(out) + 1]] <- data.table(dx = shifts$dx[i], dy = shifts$dy[i], n_ring = n_ring, beta = b)
  if (i %% 10 == 0) cat("placebo", i, "/", nrow(shifts), "\n")
}
pl <- rbindlist(out)[!is.na(beta)]
pval <- mean(pl$beta <= real)
cat(sprintf("placebos válidos: %d | média = %+.4f | dp = %.4f | P(beta_placebo <= real) = %.3f\n", nrow(pl), mean(pl$beta), sd(pl$beta), pval))
fwrite(pl, "outputs/tables/placebo_geographic_ring010.csv")
png("outputs/figures/placebo_geographic_ring010.png", width = 1000, height = 600, res = 130)
hist(pl$beta, breaks = 25, col = "#bdc3c7", main = sprintf("Placebos geográficos (%d deslocamentos da APA no oceano não tratado)\nefeito real = %+.3f, p(permutação) = %.3f", nrow(pl), real, pval), xlab = "coeficiente 'anel 0-10 km × pós' (ihs, frota pré-AIS, SST, sazonalidade por zona)")
abline(v = real, col = "#c0392b", lwd = 3); dev.off()
# temporal
pt <- p[year <= 2017]; pt[, post := as.integer(year >= 2016 & !(year == 2016 & month < 3))]
ft <- feols(ihs_y ~ i(zone, post, ref = "control") + sst + sst_anom | cell + ym + zone^month, data = pt, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
cat("\nPLACEBO TEMPORAL (tratamento fictício 2016-03, amostra 2014-2017):\n"); print(coeftable(ft)[grep("ring_0_10|apa|mona", rownames(coeftable(ft))), ])
saveRDS(list(geo = pl, real = real, temporal = ft), "outputs/models/placebos_trindade.rds")
