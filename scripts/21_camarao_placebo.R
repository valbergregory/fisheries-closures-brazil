# Background Job — placebo temporal do caso camarão: reforma fictícia em 2021
# (amostra 2018–2022, antes da reforma real). Esperado: coeficientes ~0.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
p <- fread("data/processed/panel_camarao.csv")[year <= 2022]
sst <- fread("data/interim/sst_camarao_monthly.csv")
p <- merge(p, sst[, .(cell_lon, cell_lat, year, month, sst)], by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
p[, `:=`(cell = paste(cell_lon, cell_lat), post = as.integer(year >= 2021), ihs_pre = asinh(trawl_hours_prefleet), ihs_pres = asinh(presence_hours))]
p[, status := fcase(month == 2, "new_closed", month == 5, "new_open", month %in% 3:4, "closed_both", month == 1, "mixed_jan", default = "open_both")]
p[, status := factor(status, levels = c("open_both", "new_closed", "new_open", "closed_both", "mixed_jan"))]
f <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell)
cat("PLACEBO TEMPORAL — reforma fictícia em 2021 (2018-2022):\n"); print(round(coeftable(f)[1:4, ], 4))
fwrite(as.data.table(coeftable(f)[1:4, ], keep.rownames = TRUE), "outputs/tables/camarao_placebo_temporal.csv")
