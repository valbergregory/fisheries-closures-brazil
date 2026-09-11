# Background Job — B3: desenho de calendário do defeso do camarão SE/S.
# Regime até 2022: defeso 1º/mar–31/mai (IN 189/2008; transição 2022 idem).
# Regime desde 2023: 28/jan–30/abr (Portaria 656/2022).
# Status por mês: fev = LIVRE->PROIBIDO (C1); mai = PROIBIDO->LIVRE (C2);
# mar-abr = proibido nos dois; jan = misto (só 28-31 proibido pós); jun-dez = livre nos dois (placebo).
suppressPackageStartupMessages({ library(data.table); library(fixest) })
p <- fread("data/processed/panel_camarao.csv")
sst <- fread("data/interim/sst_camarao_monthly.csv")
p <- merge(p, sst[, .(cell_lon, cell_lat, year, month, sst, sst_anom)], by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
p[, `:=`(cell = paste(cell_lon, cell_lat), post = as.integer(year >= 2023),
         ihs_all = asinh(trawl_hours), ihs_pre = asinh(trawl_hours_prefleet), ihs_pres = asinh(presence_hours),
         ihs_other = asinh(other_hours))]
p[, status := fcase(month == 2, "new_closed", month == 5, "new_open", month %in% 3:4, "closed_both",
                    month == 1, "mixed_jan", default = "open_both")]
p[, status := factor(status, levels = c("open_both", "new_closed", "new_open", "closed_both", "mixed_jan"))]
cat("painel:", nrow(p), "| células:", uniqueN(p$cell), "| anos:", paste(range(p$year), collapse = "-"), "\n")
cat("horas de arrasto por ano (toda a frota / frota pré-2023):\n")
print(p[, .(all = round(sum(trawl_hours)), prefleet = round(sum(trawl_hours_prefleet)), presence = round(sum(presence_hours))), by = year][order(year)])

specs <- list(
  A_all        = ihs_all ~ i(status, post, ref = "open_both") | cell^month + year,
  B_all_cov    = ihs_all ~ i(status, post, ref = "open_both") + ihs_pres | cell^month + year,
  C_pre_cov    = ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres | cell^month + year,
  D_pre_cov_sst= ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst + sst_anom | cell^month + year,
  E_ppml_pre   = trawl_hours_prefleet ~ i(status, post, ref = "open_both") + ihs_pres + sst + sst_anom | cell^month + year,
  F_other_gear = ihs_other ~ i(status, post, ref = "open_both") + ihs_pres | cell^month + year
)
fits <- list()
for (s in names(specs)) {
  fits[[s]] <- if (grepl("ppml", s)) fepois(specs[[s]], data = p, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
               else feols(specs[[s]], data = p, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
}
print(etable(fits, headers = names(specs), digits = 3))
etable(fits, file = "outputs/tables/camarao_calendar_main.tex", replace = TRUE, headers = names(specs))
saveRDS(fits, "outputs/models/camarao_calendar.rds")

# event study por ano para os dois meses-chave (fev e mai), frota pré-2023, cobertura + SST
cat("\n== Event study anual: fev (novo proibido) e mai (novo livre), ref 2022 ==\n")
for (mo in c(2, 5, 8)) {
  sub <- p[month %in% c(mo, 7, 9, 10, 11, 12)]; sub[, tm := as.integer(month == mo)]; sub[, rel := year - 2023L]
  f <- feols(ihs_pre ~ i(rel, tm, ref = -1) + ihs_pres + sst + sst_anom | cell^month + year, data = sub, vcov = conley(200, distance = "spherical") ~ cell_lat + cell_lon)
  ct <- coeftable(f); cat(sprintf("mês %d vs jul-dez:\n", mo)); print(round(ct[grep("rel", rownames(ct)), c(1, 2, 4)], 3))
}
