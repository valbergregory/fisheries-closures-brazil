-- Amostra econométrica: janela do caso, exclusões documentadas em aud.exclusions.
CREATE TABLE IF NOT EXISTS aud.exclusions (
  cell_id VARCHAR, reason VARCHAR, rule_ref VARCHAR, excluded_at TIMESTAMP
);
-- Exemplo de extração (fase 2):
-- CREATE VIEW fx.sample_trindade AS
-- SELECT * FROM fx.panel_month
-- WHERE year BETWEEN 2016 AND 2020
--   AND cell_id NOT IN (SELECT cell_id FROM aud.exclusions);
