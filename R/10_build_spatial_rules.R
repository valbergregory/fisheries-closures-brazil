# 10_build_spatial_rules.R — geometrias operacionais das regras.
# Fase 1 (2026-09-10): polígonos de UC (caso Trindade). Distâncias são
# GEODÉSICAS (sf + s2), sem reprojeção — fecha a decisão D4 para este caso.

load_mpa_polygons <- function(path = "data/raw/uc_trindade_test.geojson") {
  uc <- sf::read_sf(path)
  uc <- sf::st_transform(uc, 4326)
  uc <- sf::st_make_valid(uc)
  stopifnot(all(sf::st_is_valid(uc)), all(c("MONA", "APA") %in% uc$sigla_cate))
  uc[, c("nomeuc", "cnuc", "sigla_cate", "criacaoato", "areahaalb", "geometry")]
}

# Distância assinada (km) de pontos à fronteira de um polígono:
# negativa dentro, positiva fora. Geodésica.
signed_distance_km <- function(points, polygon) {
  boundary <- sf::st_cast(sf::st_union(polygon), "MULTILINESTRING")
  d <- as.numeric(sf::st_distance(points, boundary)) / 1000
  inside <- lengths(sf::st_within(points, sf::st_union(polygon))) > 0
  ifelse(inside, -d, d)
}

# Zonas mutuamente exclusivas a partir dos centros de célula.
# rings_km: limites externos dos anéis FORA da APA; além do último = controle.
build_cell_zones <- function(cells, mpa, rings_km = c(10, 25, 50, 100)) {
  stopifnot(all(c("cell_lon", "cell_lat") %in% names(cells)))
  pts <- sf::st_as_sf(as.data.frame(cells), coords = c("cell_lon", "cell_lat"),
                      crs = 4326, remove = FALSE)
  mona <- mpa[mpa$sigla_cate == "MONA", ]
  apa  <- mpa[mpa$sigla_cate == "APA", ]
  out <- data.table::as.data.table(sf::st_drop_geometry(pts))
  out[, dist_mona_km := signed_distance_km(pts, mona)]
  out[, dist_apa_km  := signed_distance_km(pts, apa)]
  breaks <- c(0, rings_km)
  ring_lab <- paste0("ring_", head(breaks, -1), "_", tail(breaks, -1))
  out[, zone := data.table::fcase(
    dist_mona_km <= 0, "mona",
    dist_apa_km  <= 0, "apa",
    dist_apa_km  >  max(rings_km), "control",
    default = ring_lab[pmax(1, findInterval(dist_apa_km, breaks, left.open = TRUE))]
  )]
  out[, zone := factor(zone, levels = c("control", ring_lab[length(ring_lab):1], "apa", "mona"))]
  out[]
}
