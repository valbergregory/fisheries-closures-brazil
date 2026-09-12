# Pipeline targets — orquestração REAL (2026-09-12).
# Estratégia: alvos de arquivo (format = "file") que executam os builders
# Python e os scripts R já existentes e devolvem seus produtos. targets
# rastreia entradas (metadados/checksums dos dados brutos, configs, scripts)
# e só reexecuta o que mudou. Rodar: Rscript scripts/04_run_pipeline.R
# (ou targets::tar_make() no Console). Os scripts R são chamados por
# Rscript em processo separado (source() dentro do processo dá segfault
# neste ambiente — ver docs/RESUME_HERE.md).
library(targets)
library(tarchetypes)

tar_option_set(packages = c("data.table", "jsonlite", "yaml"), format = "rds", error = "stop")
for (f in list.files("R", pattern = "^0[125].*[.]R$", full.names = TRUE)) source(f)

RSCRIPT <- if (nzchar(Sys.getenv("RSCRIPT"))) Sys.getenv("RSCRIPT") else file.path(R.home("bin"), "Rscript")
run_r <- function(script, outputs) {
  log <- file.path("outputs/logs", paste0(basename(script), ".log"))
  status <- system2(RSCRIPT, shQuote(script), stdout = log, stderr = paste0(log, ".err"))
  if (!identical(status, 0L)) stop("falhou: ", script, " (status ", status, ")")
  stopifnot(all(file.exists(outputs))); outputs
}
run_py <- function(script, outputs) {
  log <- file.path("outputs/logs", paste0(basename(script), ".log"))
  Sys.setenv(PYTHONIOENCODING = "utf-8")
  status <- system2("python", shQuote(script), stdout = log, stderr = paste0(log, ".err"))
  if (!identical(status, 0L)) stop("falhou: ", script, " (status ", status, ")")
  stopifnot(all(file.exists(outputs))); outputs
}

list(
  # ---- configuração e registro regulatório -------------------------------
  tar_target(cfg_file, "config/config.yml", format = "file"),
  tar_target(cfg, load_config(cfg_file)),
  tar_target(policy_sources_file, "config/policy_sources.yml", format = "file"),
  tar_target(policy_catalog, load_policy_catalog(policy_sources_file)),
  tar_target(rule_files, list.files("outputs/policies", pattern = "[.]json$", full.names = TRUE), format = "file"),
  tar_target(policy_registry, build_policy_registry(rule_files, require_validated = FALSE)),
  tar_target(policy_registry_validated_only,
             build_policy_registry(rule_files[vapply(rule_files, function(f) isTRUE(jsonlite::read_json(f)$validation$human_validated), logical(1))],
                                   require_validated = TRUE)),

  # ---- entradas brutas rastreadas por checksum (não pelos JSON de 4 GB) ----
  tar_target(checksums_gfw, "data/metadata/checksums_gfw.txt", format = "file"),
  tar_target(checksums_legal, "data/metadata/checksums_legal.txt", format = "file"),

  # ---- Caso I: Trindade --------------------------------------------------
  tar_target(script_pilot, c("python/feasibility_pilot.py", "python/merge_gfw_pilot.py", "python/merge_gfw_presence.py",
                             "python/build_exogenous_coverage.py", "python/build_preais_cell_panel.py"), format = "file"),
  tar_target(panel_trindade_interim, {
    cfg_file; checksums_gfw; script_pilot
    run_py("python/feasibility_pilot.py", "data/interim/pilot_panel_trindade.csv")
    run_py("python/merge_gfw_pilot.py", "data/interim/pilot_panel_trindade.csv")
    run_py("python/merge_gfw_presence.py", "data/interim/pilot_panel_trindade.csv")
    run_py("python/build_exogenous_coverage.py", "data/interim/coverage_exog_trindade.csv")
    run_py("python/build_preais_cell_panel.py", "data/interim/pilot_panel_trindade.csv")
  }, format = "file"),
  tar_target(sst_trindade, { checksums_gfw; panel_trindade_interim
    run_r("scripts/23_sst_trindade.R", "data/interim/sst_trindade_monthly.csv") }, format = "file"),
  tar_target(trindade_full, { panel_trindade_interim; sst_trindade
    run_r("scripts/17_phase1_full_2024.R", c("data/processed/panel_trindade_phase1.csv",
                                             "outputs/tables/eventstudy_2014_2024_preais_trindade.csv",
                                             "outputs/models/full_2014_2024_trindade.rds")) }, format = "file"),
  tar_target(trindade_placebos, { trindade_full
    run_r("scripts/18_phase1_placebos.R", c("outputs/tables/placebo_geographic_ring010.csv", "outputs/models/placebos_trindade.rds")) }, format = "file"),
  tar_target(trindade_vessels, { checksums_gfw
    run_py("python/build_vessel_panel.py", "data/processed/vessel_zone_month_trindade.csv")
    run_r("scripts/14_phase1_vessel_decomposition.R", c("outputs/tables/apa_decomposition_by_origin.csv", "data/processed/vessel_origin_trindade.csv")) }, format = "file"),

  # ---- Caso II: camarão ----------------------------------------------------
  tar_target(sst_camarao, { checksums_gfw
    run_r("scripts/19_camarao_sst_mask.R", "data/interim/sst_camarao_monthly.csv") }, format = "file"),
  tar_target(panel_camarao, { checksums_gfw; sst_camarao
    run_py("python/build_camarao_panel.py", c("data/processed/panel_camarao.csv", "data/processed/panel_camarao_gear.csv")) }, format = "file"),
  tar_target(camarao_models, { panel_camarao
    run_r("scripts/20_camarao_calendar.R", c("outputs/models/camarao_calendar.rds", "outputs/tables/camarao_calendar_main.tex",
                                            "outputs/models/camarao_eventstudy.rds", "outputs/figures/camarao_eventstudy.png")) }, format = "file"),
  tar_target(camarao_placebo, { panel_camarao
    run_r("scripts/21_camarao_placebo.R", "outputs/tables/camarao_placebo_temporal.csv") }, format = "file"),
  tar_target(camarao_leakage, { panel_camarao
    run_r("scripts/22_camarao_leakage_ri.R", c("outputs/tables/camarao_leakage_decomposition.csv",
                                              "outputs/tables/camarao_placebo_months.csv", "outputs/tables/camarao_gear_substitution.csv")) }, format = "file"),

  # ---- Seguro-Defeso (agregado municipal; microdados fora do Git) ------------
  tar_target(seguro_defeso_agg, "data/processed/seguro_defeso_municipio_mes.csv", format = "file")
)
