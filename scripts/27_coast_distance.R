# D3 — distância GEODÉSICA de cada célula à linha de costa real (malhas do
# IBGE, qualidade máxima) e UF adjacente. Corrige a coluna dist_land_km do
# painel do camarão, que vinha da máscara do OISST (0,25°) e superestimava a
# distância por um fator de até 7 perto da costa de SC.
# Rodar: Rscript scripts/27_coast_distance.R
suppressPackageStartupMessages({ library(data.table); library(sf) })
sf_use_s2(TRUE)

ufs <- c("ES", "RJ", "SP", "PR", "SC", "RS")
geoms <- lapply(ufs, function(u) {
  g <- sf::read_sf(file.path("data/raw/ibge", paste0("uf_", u, ".json")))
  g$uf <- u
  sf::st_make_valid(g["uf"])
})
land <- do.call(rbind, geoms) |> sf::st_transform(4326)
coast <- sf::st_cast(sf::st_union(land), "MULTILINESTRING")
cat("UFs carregadas:", paste(ufs, collapse = ", "), "\n")

annotate <- function(panel_file, out_file) {
  p <- fread(panel_file)
  cells <- unique(p[, .(cell_lon, cell_lat)])
  pts <- sf::st_as_sf(as.data.frame(cells), coords = c("cell_lon", "cell_lat"), crs = 4326, remove = FALSE)
  cells[, coast_km := round(as.numeric(sf::st_distance(pts, coast)) / 1000, 1)]
  # UF adjacente = a UF cuja fronteira está mais próxima da célula
  dmat <- sf::st_distance(pts, land)
  cells[, uf := land$uf[apply(dmat, 1, which.min)]]
  cells[, on_land := lengths(sf::st_within(pts, sf::st_union(land))) > 0]
  p <- merge(p[, setdiff(names(p), c("coast_km", "uf", "on_land")), with = FALSE], cells,
             by = c("cell_lon", "cell_lat"), all.x = TRUE)
  fwrite(p, out_file)
  cat(sprintf("%s: %d células | em terra: %d | costa: min %.1f, mediana %.1f, máx %.1f km\n",
              basename(out_file), nrow(cells), sum(cells$on_land),
              min(cells$coast_km), median(cells$coast_km), max(cells$coast_km)))
  cells
}
c1 <- annotate("data/processed/panel_camarao.csv", "data/processed/panel_camarao.csv")
cat("\ncélulas por UF (camarão):\n"); print(c1[, .N, by = uf][order(-N)])
cat("\ndistância antiga (máscara OISST) vs nova (costa IBGE), células de maior esforço:\n")
p <- fread("data/processed/panel_camarao.csv")
top <- p[, .(h = sum(trawl_hours), coast_km = coast_km[1], old = dist_land_km[1], uf = uf[1]), by = .(cell_lon, cell_lat)][order(-h)][1:8]
print(top[, .(cell_lon, cell_lat, uf, antiga_km = old, nova_km = coast_km, horas = round(h))])
