# testthat — invariantes do painel piloto (roda após scripts/03_run_feasibility.R)
test_that("painel piloto tem estrutura e tratamento coerentes", {
  f <- "../../data/interim/pilot_panel_trindade.csv"
  skip_if_not(file.exists(f), "piloto ainda não executado")
  p <- data.table::fread(f)
  expect_true(all(c("zone", "post", "treated_mona", "treated_apa") %in% names(p)))
  expect_setequal(unique(p$zone), c("mona", "apa", "outside"))
  # ninguém tratado antes do Decreto 9.312/2018
  expect_equal(p[post == 0, sum(treated_mona) + sum(treated_apa)], 0)
  # tratamento só dentro dos polígonos
  expect_equal(p[zone == "outside", sum(treated_apa)], 0)
})
