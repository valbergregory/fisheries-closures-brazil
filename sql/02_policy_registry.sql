-- Registro regulatório: 1 linha = 1 regra atômica (espécie x área x período x modalidade)
CREATE TABLE IF NOT EXISTS reg.rules (
  rule_id VARCHAR PRIMARY KEY,
  norm_id VARCHAR NOT NULL,
  norm_type VARCHAR,
  issuing_authority VARCHAR,
  period_start VARCHAR,          -- MM-DD (recorrente) ou YYYY-MM-DD
  period_end VARCHAR,
  recurrence VARCHAR CHECK (recurrence IN ('annual','one_off','permanent')),
  first_effective_year INTEGER,
  uf VARCHAR,                    -- lista separada por vírgula
  geometry_status VARCHAR,
  seguro_defeso_linked BOOLEAN,
  human_validated BOOLEAN NOT NULL,
  version INTEGER DEFAULT 1,
  json_path VARCHAR              -- fonte completa em outputs/policies/
);
CREATE TABLE IF NOT EXISTS reg.rule_species (
  rule_id VARCHAR,
  scientific_name VARCHAR,
  common_name VARCHAR,
  PRIMARY KEY (rule_id, scientific_name)
);
CREATE TABLE IF NOT EXISTS reg.norms (
  norm_id VARCHAR PRIMARY KEY,
  name VARCHAR, publication_date DATE, dou_reference VARCHAR,
  official_url VARCHAR, sha256 VARCHAR, retrieved BOOLEAN
);
