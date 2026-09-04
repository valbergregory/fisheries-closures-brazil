-- DuckDB — esquema base (fase 1: executar via DBI/duckdb no R).
-- Convenção: dados ficam em Parquet (data/processed/); DuckDB consulta por cima.
CREATE SCHEMA IF NOT EXISTS reg;    -- registro regulatório
CREATE SCHEMA IF NOT EXISTS geo;    -- geometrias e grades
CREATE SCHEMA IF NOT EXISTS fx;     -- esforço e outcomes
CREATE SCHEMA IF NOT EXISTS aud;    -- auditoria
