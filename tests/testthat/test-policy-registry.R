# testthat — registro regulatório
test_that("catálogo jurídico carrega sem norm_id duplicado", {
  source("../../R/01_config.R")
  cat_ <- load_policy_catalog("../../config/policy_sources.yml")
  expect_gt(nrow(cat_), 5)
  expect_false(anyDuplicated(cat_$norm_id) > 0)
})

test_that("registro bloqueia regra sem validação humana quando exigido", {
  source("../../R/05_build_policy_registry.R")
  files <- list.files("../../outputs/policies", pattern = "\.json$", full.names = TRUE)
  expect_error(build_policy_registry(files, require_validated = TRUE),
               "validação humana")
  reg <- build_policy_registry(files, require_validated = FALSE)
  expect_true("PORT_SAP_MAPA_656_2022_r1" %in% reg$rule_id)
})
