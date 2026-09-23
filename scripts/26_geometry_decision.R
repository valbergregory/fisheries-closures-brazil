# D3 — decisão de geometria fundamentada em dados, com distância GEODÉSICA à
# linha de costa do IBGE (scripts/27) e exclusão de águas interiores (células
# dentro dos polígonos estaduais: Lagoa dos Patos, baías — a Portaria
# 656/2022 alcança Mar Territorial e ZEE).
# Rodar: Rscript scripts/26_geometry_decision.R
suppressPackageStartupMessages({ library(data.table); library(fixest) })
p <- fread("data/processed/panel_camarao.csv")
stopifnot(all(c("coast_km", "uf", "on_land") %in% names(p)))
cat("painel bruto:", uniqueN(paste(p$cell_lon, p$cell_lat)), "células |",
    "em águas interiores/terra:", uniqueN(p[on_land == TRUE, paste(cell_lon, cell_lat)]), "\n")
cat("horas de arrasto em águas interiores (excluídas):", round(p[on_land == TRUE, sum(trawl_hours)]), "\n\n")
p <- p[on_land == FALSE]

sst <- fread("data/interim/sst_camarao_monthly.csv")
p <- merge(p, sst[, .(cell_lon, cell_lat, year, month, sst)], by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
p[, `:=`(cell = paste(cell_lon, cell_lat), post = as.integer(year >= 2023),
         ihs_pre = asinh(trawl_hours_prefleet), ihs_pres = asinh(presence_hours))]
p[, status := fcase(month == 2, "new_closed", month == 5, "new_open", month %in% 3:4, "closed_both",
                    month == 1, "mixed_jan", default = "open_both")]
p[, status := factor(status, levels = c("open_both", "new_closed", "new_open", "closed_both", "mixed_jan"))]

p[, band := cut(coast_km, breaks = c(-1, 25, 50, 75, 100, 150, 1000),
                labels = c("0-25", "25-50", "50-75", "75-100", "100-150", ">150"))]
d <- p[, .(cells = uniqueN(cell), trawl = round(sum(trawl_hours)), hours_per_cell = round(sum(trawl_hours) / uniqueN(cell))), by = band][order(band)]
d[, share := round(100 * trawl / sum(trawl), 1)]
cat("== Onde o arrasto opera (distância REAL à costa, 2018-2024) ==\n"); print(d)
cat(sprintf("\nAcumulado: até 50 km %.1f%% | até 100 km %.1f%% | até 150 km %.1f%%\n",
            d[band %in% c("0-25", "25-50"), sum(share)],
            d[band %in% c("0-25", "25-50", "50-75", "75-100"), sum(share)],
            d[band != ">150", sum(share)]))
fwrite(d, "outputs/tables/camarao_effort_by_distance_band.csv")

cat("\n== Sensibilidade do efeito ao raio (ihs, frota pré-2023, cobertura + SST) ==\n")
res <- list()
for (km in c(25, 50, 100, 150, 200, 400)) {
  sub <- p[coast_km <= km]
  f <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = sub, cluster = ~cell)
  ct <- coeftable(f)
  res[[length(res) + 1]] <- data.table(raio_km = km, celulas = uniqueN(sub$cell), horas = round(sub[, sum(trawl_hours)]),
    fev = round(ct["status::new_closed:post", 1], 3), fev_se = round(ct["status::new_closed:post", 2], 3),
    mai = round(ct["status::new_open:post", 1], 3), mai_se = round(ct["status::new_open:post", 2], 3),
    marabr = round(ct["status::closed_both:post", 1], 3))
}
tab <- rbindlist(res); print(tab); fwrite(tab, "outputs/tables/camarao_geometry_sensitivity.csv")

cat("\n== Efeito por faixa de distância ==\n")
p[, band2 := fifelse(coast_km <= 50, "0-50 km", fifelse(coast_km <= 150, "50-150 km", ">150 km"))]
for (b in c("0-50 km", "50-150 km", ">150 km")) {
  sub <- p[band2 == b]
  if (uniqueN(sub$cell) < 30) next
  f <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = sub, cluster = ~cell)
  ct <- coeftable(f)
  cat(sprintf("%-10s  fev %+.3f (%.3f) | mai %+.3f (%.3f) | células %d | horas %d\n", b,
              ct["status::new_closed:post", 1], ct["status::new_closed:post", 2],
              ct["status::new_open:post", 1], ct["status::new_open:post", 2],
              uniqueN(sub$cell), round(sub[, sum(trawl_hours)])))
}
cat("\n== Esforço por UF (células oceânicas, horas de arrasto) ==\n")
print(p[, .(celulas = uniqueN(cell), horas = round(sum(trawl_hours)), horas_prefleet = round(sum(trawl_hours_prefleet))), by = uf][order(-horas)])
