-- Painel analítico célula x mês (ou semana — decisão D6).
CREATE TABLE IF NOT EXISTS fx.panel_month (
  cell_id VARCHAR, year INTEGER, month INTEGER,
  fishing_hours DOUBLE, vessels INTEGER, presence BOOLEAN,
  ais_coverage DOUBLE,           -- controle de cobertura satelital
  sst DOUBLE, chlorophyll DOUBLE,
  treated BOOLEAN, post BOOLEAN, zone VARCHAR, dist_boundary_km DOUBLE,
  PRIMARY KEY (cell_id, year, month)
);
