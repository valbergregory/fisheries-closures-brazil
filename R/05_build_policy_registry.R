# 05_build_policy_registry.R — registro regulatório a partir dos JSONs
# validados contra config/policy_rule_schema.json.

build_policy_registry <- function(rule_files, require_validated = TRUE) {
  rules <- lapply(rule_files, jsonlite::read_json)
  registry <- data.table::rbindlist(lapply(rules, function(r) {
    data.table::data.table(
      rule_id = r$rule_id,
      norm_id = r$norm_id,
      species_n = length(r$species),
      uf = paste(unlist(r$area$uf), collapse = ","),
      period_start = r$period$start,
      period_end = r$period$end,
      recurrence = r$period$recurrence,
      seguro_defeso_linked = isTRUE(r$seguro_defeso_linked),
      human_validated = isTRUE(r$validation$human_validated),
      geometry_status = r$area$geometry_status
    )
  }))
  stopifnot(!anyDuplicated(registry$rule_id))
  if (require_validated && any(!registry$human_validated)) {
    stop("Regras sem validação humana: ",
         paste(registry[human_validated == FALSE, rule_id], collapse = ", "),
         " — uso científico bloqueado (ver docs/policy_registry_protocol.md).")
  }
  registry
}
