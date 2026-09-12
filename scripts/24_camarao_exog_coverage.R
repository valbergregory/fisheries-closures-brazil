# Caso camarão com cobertura EXÓGENA: (1) placebo — cargueiros por status×pós;
# (2) spec D + controle por ihs(cargo) e ihs(nonfish). Rodar direto com Rscript.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
p <- fread("data/processed/panel_camarao.csv"); stopifnot("cargo_hours" %in% names(p))
sst <- fread("data/interim/sst_camarao_monthly.csv")
p <- merge(p, sst[, .(cell_lon, cell_lat, year, month, sst)], by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
p[, `:=`(cell = paste(cell_lon, cell_lat), post = as.integer(year >= 2023), ihs_pre = asinh(trawl_hours_prefleet),
         ihs_pres = asinh(presence_hours), ihs_cargo = asinh(cargo_hours), ihs_nonf = asinh(nonfish_hours))]
p[, status := fcase(month == 2, "new_closed", month == 5, "new_open", month %in% 3:4, "closed_both", month == 1, "mixed_jan", default = "open_both")]
p[, status := factor(status, levels = c("open_both", "new_closed", "new_open", "closed_both", "mixed_jan"))]
cat("cargo h/célula-mês por ano:\n"); print(p[, .(cargo = round(mean(cargo_hours), 2), nonfish = round(mean(nonfish_hours), 2), pres = round(mean(presence_hours), 2)), by = year][order(year)])
m0 <- feols(ihs_cargo ~ i(status, post, ref = "open_both") + sst | cell^month + year, data = p, cluster = ~cell)
m1 <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell)
m2 <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_cargo + sst | cell^month + year, data = p, cluster = ~cell)
m3 <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_nonf + sst | cell^month + year, data = p, cluster = ~cell)
m4 <- fepois(trawl_hours_prefleet ~ i(status, post, ref = "open_both") + ihs_cargo + sst | cell^month + year, data = p, cluster = ~cell)
print(etable(m0, m1, m2, m3, m4, headers = c("PLACEBO cargo", "D presença total", "+cargo", "+nonfish", "PPML +cargo"), digits = 3))
etable(m0, m1, m2, m3, m4, file = "outputs/tables/camarao_exog_coverage.tex", replace = TRUE, headers = c("placebo cargo", "pres", "cargo", "nonfish", "PPML cargo"))
saveRDS(list(placebo = m0, pres = m1, cargo = m2, nonf = m3, ppml = m4), "outputs/models/camarao_exog_coverage.rds")
