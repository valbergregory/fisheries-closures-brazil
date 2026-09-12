test_that("painel do camarão tem invariantes de calendário e cobertura", {
  f <- "../../data/processed/panel_camarao.csv"; skip_if_not(file.exists(f))
  p <- data.table::fread(f)
  expect_true(all(c("trawl_hours", "trawl_hours_prefleet", "presence_hours") %in% names(p)))
  expect_true(all(p$trawl_hours_prefleet <= p$trawl_hours + 1e-6))
  expect_equal(p[, .N, by = .(cell_lon, cell_lat)][, unique(N)], 84)   # 2018–2024
  expect_true(all(p$cell_lat >= -33.75 & p$cell_lat <= -21.30))
})
test_that("resultados do camarão: sinais opostos em fev e mai (frota pré-2023)", {
  f <- "../../outputs/models/camarao_calendar.rds"; skip_if_not(file.exists(f))
  m <- readRDS(f)$D; b <- coef(m)
  expect_lt(b[["status::new_closed:post"]], 0)
  expect_gt(b[["status::new_open:post"]], 0)
})
test_that("registro regulatório tem >= 19 regras válidas no esquema", {
  files <- list.files("../../outputs/policies", pattern = "[.]json$", full.names = TRUE)
  expect_gte(length(files), 19)
  source("../../R/05_build_policy_registry.R")
  reg <- build_policy_registry(files, require_validated = FALSE)
  expect_false(anyDuplicated(reg$rule_id) > 0)
})
