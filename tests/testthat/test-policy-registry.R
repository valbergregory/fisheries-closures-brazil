# testthat — registro regulatório
test_that("catálogo jurídico carrega sem norm_id duplicado", {
  source("../../R/01_config.R")
  cat_ <- load_policy_catalog("../../config/policy_sources.yml")
  expect_gt(nrow(cat_), 5)
  expect_false(anyDuplicated(cat_$norm_id) > 0)
})

test_that("registro bloqueia regra sem validação humana quando exigido", {
  source("../../R/05_build_policy_registry.R")
  files <- list.files("../../outputs/policies", pattern = "[.]json$", full.names = TRUE)
  expect_error(build_policy_registry(files, require_validated = TRUE),
               "validação humana")
  reg <- build_policy_registry(files, require_validated = FALSE)
  expect_true("PORT_SAP_MAPA_656_2022_r1" %in% reg$rule_id)
})

test_that("registro cobre as regras da sardinha e a restrição permanente", {
  source("../../R/05_build_policy_registry.R")
  files <- list.files("../../outputs/policies", pattern = "[.]json$", full.names = TRUE)
  reg <- build_policy_registry(files, require_validated = FALSE)
  expect_true(all(c("IN_IBAMA_15_2009_r1", "IN_IBAMA_15_2009_r2",
                    "IN_MAPA_18_2020_r1") %in% reg$rule_id))
  # restrições permanentes convivem com defesos anuais no mesmo registro (D12)
  expect_true("permanent" %in% reg$recurrence)
  expect_true("annual" %in% reg$recurrence)
})
