# Pipeline targets — esqueleto. A sequência EXECUTÁVEL da fase 1 está em
# docs/RESUME_HERE.md (scripts 08–20 + 4 scripts Python); a migração para
# alvos targets é o passo C4 pendente (funções já existem em R/).
# Ordem lógica (ver docs/research_protocol.md, seção 18):
# config -> catálogo jurídico -> download normas -> checksums -> extração ->
# revisão humana (gate manual) -> registro de regras -> polígonos -> esforço ->
# ambiente -> Seguro-Defeso/fiscalização -> tratamento -> painel -> auditoria ->
# descritivas -> modelo principal -> spillovers -> robustez -> figuras ->
# tabelas -> dashboard -> artigo.
#
# NENHUM alvo de estimação definitiva está ativo. Alvos comentados são
# ativados por fase, após aprovação do relatório de viabilidade.

library(targets)
library(tarchetypes)

tar_option_set(
  packages = c("data.table", "jsonlite", "yaml", "httr2", "curl"),
  # sf/terra/duckdb/arrow entram via renv na fase 1 (decisão D2)
  format = "rds",
  error = "stop"
)

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

list(
  # ---- 1. Configuração --------------------------------------------------
  tar_target(cfg_file, "config/config.yml", format = "file"),
  tar_target(cfg, load_config(cfg_file)),

  # ---- 2-4. Catálogo jurídico, normas, checksums ------------------------
  tar_target(policy_sources_file, "config/policy_sources.yml", format = "file"),
  tar_target(policy_catalog, load_policy_catalog(policy_sources_file)),
  tar_target(legal_files, track_legal_files("data/legal"), format = "file"),
  tar_target(legal_checksums, checksum_files(legal_files)),

  # ---- 7. Registro de regras (só regras humanamente validadas passam) ---
  tar_target(rule_files, list.files("outputs/policies", pattern = "\\.json$",
                                    full.names = TRUE), format = "file"),
  tar_target(policy_registry, build_policy_registry(rule_files,
                                                    require_validated = FALSE))
  # require_validated = TRUE antes de qualquer uso científico.

  # ---- Fase 1 (ativar após viabilidade aprovada) ------------------------
  # tar_target(mpa_polygons, download_mpa_polygons(cfg)),
  # tar_target(effort_raw, download_fishing_effort(cfg)),        # exige GFW_TOKEN
  # tar_target(env_covariates, download_environment(cfg)),
  # tar_target(social_data, download_social_data(cfg)),          # Seguro-Defeso
  # tar_target(spatial_rules, build_spatial_rules(policy_registry, mpa_polygons)),
  # tar_target(treatment, build_treatment(spatial_rules, cfg)),
  # tar_target(panel, build_panel(effort_raw, treatment, env_covariates)),
  # tar_target(quality_report, data_quality_checks(panel)),
  # tar_target(descriptives, descriptive_analysis(panel)),
  # ---- Fase 2 (estimação — só após pré-registro dos estimandos) ---------
  # tar_target(es_main, run_event_study(panel, cfg)),
  # tar_target(did_spatial, run_spatial_did(panel, cfg)),
  # tar_target(rdd_geo, run_geographic_rdd(panel, mpa_polygons, cfg)),
  # tar_target(sdid, run_synthetic_did(panel, cfg)),
  # tar_target(spill, run_spillovers(panel, cfg)),
  # tar_target(robust, run_robustness(panel, cfg)),
  # tar_target(figs, make_figures(descriptives, es_main, spill)),
  # tar_target(tabs, make_tables(did_spatial, rdd_geo, robust)),
  # tar_target(dash, build_dashboard_data(panel, policy_registry))
)
