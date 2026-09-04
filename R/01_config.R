# 01_config.R — carga e validação da configuração.

load_config <- function(path = "config/config.yml") {
  cfg <- yaml::read_yaml(path)
  stopifnot(
    is.character(cfg$project$name),
    cfg$project$stage %in% c("feasibility", "phase1", "phase2"),
    is.numeric(cfg$spatial$grid_step_deg)
  )
  cfg
}

load_policy_catalog <- function(path = "config/policy_sources.yml") {
  cat_ <- yaml::read_yaml(path)
  norms <- data.table::rbindlist(
    lapply(cat_$norms, function(n) data.table::data.table(
      norm_id = n$norm_id, name = n$name, subject = n$subject,
      retrieved = isTRUE(n$retrieved)
    ))
  )
  stopifnot(!anyDuplicated(norms$norm_id))
  norms
}
