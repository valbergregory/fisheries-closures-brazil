-- Exposição espaço-temporal: célula x regra x janela de vigência.
-- Geometria calculada no R/sf (ou extensão spatial do DuckDB — decisão D5);
-- aqui apenas o resultado tabular.
CREATE TABLE IF NOT EXISTS geo.cells (
  cell_id VARCHAR PRIMARY KEY,   -- h3 ou lon/lat concatenado
  lon DOUBLE, lat DOUBLE,
  zone VARCHAR,                  -- mona | apa | outside (por caso)
  dist_boundary_km DOUBLE,
  depth_m DOUBLE, dist_coast_km DOUBLE
);
CREATE TABLE IF NOT EXISTS geo.cell_rule_exposure (
  cell_id VARCHAR, rule_id VARCHAR,
  date_start DATE, date_end DATE,
  inside BOOLEAN, buffer_ring VARCHAR,   -- ex.: in_0_10km, out_10_25km
  PRIMARY KEY (cell_id, rule_id, date_start)
);
