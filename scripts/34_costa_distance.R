# Distância à costa para as células do Norte/Nordeste (mesmo critério da D3)
# e junção com o painel do SE/S -> painel nacional para o desenho de triplas
# diferenças. Rodar: Rscript scripts/34_costa_distance.R
suppressPackageStartupMessages({ library(data.table); library(sf) })
sf_use_s2(TRUE)

UF_N  <- c("AP", "PA", "MA")
UF_NE <- c("PI", "CE", "RN", "PB", "PE", "AL", "SE", "BA")
dir.create("data/raw/ibge", showWarnings = FALSE, recursive = TRUE)
for (u in c(UF_N, UF_NE)) {
  f <- file.path("data/raw/ibge", paste0("uf_", u, ".json"))
  if (!file.exists(f)) {
    url <- sprintf("https://servicodados.ibge.gov.br/api/v3/malhas/estados/%s?formato=application/vnd.geo+json&qualidade=maxima", u)
    try(curl::curl_download(url, f, quiet = TRUE), silent = TRUE)
  }
}
ok <- file.exists(file.path("data/raw/ibge", paste0("uf_", c(UF_N, UF_NE), ".json")))
cat("malhas baixadas:", sum(ok), "de", length(ok), "\n")
land <- do.call(rbind, lapply(c(UF_N, UF_NE)[ok], function(u) {
  g <- read_sf(file.path("data/raw/ibge", paste0("uf_", u, ".json"))); g$uf <- u; st_make_valid(g["uf"]) }))
coast <- st_cast(st_union(land), "MULTILINESTRING")

p <- fread("data/processed/panel_costa_raw.csv")
cells <- unique(p[, .(region, cell_lon, cell_lat)])
pts <- st_as_sf(as.data.frame(cells), coords = c("cell_lon", "cell_lat"), crs = 4326, remove = FALSE)
cells[, coast_km := round(as.numeric(st_distance(pts, coast)) / 1000, 1)]
dm <- st_distance(pts, land); cells[, uf := land$uf[apply(dm, 1, which.min)]]
cells[, on_land := lengths(st_within(pts, st_union(land))) > 0]
p <- merge(p, cells, by = c("region", "cell_lon", "cell_lat"))
cat("células:", nrow(cells), "| em terra:", sum(cells$on_land), "| <=100 km:", sum(cells$coast_km <= 100), "\n")
p <- p[on_land == FALSE & coast_km <= 100]
fwrite(p, "data/processed/panel_costa.csv")
cat("painel Norte/Nordeste (filtro D3):", nrow(p), "linhas |",
    uniqueN(paste(p$cell_lon, p$cell_lat)), "células\n")
print(p[, .(horas_arrasto = round(sum(trawl_hours)), celulas = uniqueN(paste(cell_lon, cell_lat))), by = region])
