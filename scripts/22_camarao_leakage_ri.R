# Background Job — caso camarão: (1) decomposição TEMPORAL do leakage
# (protocolo §7), (2) inferência por randomização sobre meses-placebo,
# (3) substituição por arte (C5, versão independente da D8).
# Rodar diretamente: Rscript scripts/22_camarao_leakage_ri.R
suppressPackageStartupMessages({ library(data.table); library(fixest) })
p <- fread("data/processed/panel_camarao.csv")
sst <- fread("data/interim/sst_camarao_monthly.csv")
p <- merge(p, sst[, .(cell_lon, cell_lat, year, month, sst)], by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
p[, `:=`(cell = paste(cell_lon, cell_lat), post = as.integer(year >= 2023), ihs_pre = asinh(trawl_hours_prefleet), ihs_pres = asinh(presence_hours))]
p[, status := fcase(month == 2, "new_closed", month == 5, "new_open", month %in% 3:4, "closed_both", month == 1, "mixed_jan", default = "open_both")]
p[, status := factor(status, levels = c("open_both", "new_closed", "new_open", "closed_both", "mixed_jan"))]

# ---------- (1) decomposição temporal (PPML, frota pré-2023): obs - obs/exp(beta) por status ----------
m <- fepois(trawl_hours_prefleet ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell)
b <- coef(m); nm <- names(b)
obs <- p[post == 1, .(hours_obs = sum(trawl_hours_prefleet), n_months = uniqueN(paste(year, month))), by = status]
obs[, beta := sapply(as.character(status), function(s) { k <- paste0("status::", s, ":post"); if (k %in% nm) b[[k]] else 0 })]
obs[, hours_cf := hours_obs / exp(beta)]; obs[, change := hours_obs - hours_cf]
obs[, change_per_month := change / n_months]
setorder(obs, status)
cat("== Decomposição temporal do leakage (2023–2024, frota pré-2023, PPML) ==\n"); print(obs[, .(status, n_months, hours_obs = round(hours_obs), beta = round(beta, 3), change = round(change), change_per_month = round(change_per_month))])
net <- obs[, sum(change)]
cat(sprintf("\n  fev (novo proibido): %+.0f h\n  mai (novo livre):    %+.0f h\n  mar–abr:             %+.0f h\n  jan (misto):         %+.0f h\n  LÍQUIDO 2023–24:     %+.0f h (%+.1f%% do observado nos meses tratados)\n",
            obs[status == "new_closed", change], obs[status == "new_open", change], obs[status == "closed_both", change], obs[status == "mixed_jan", change],
            net, 100 * net / obs[status != "open_both", sum(hours_obs)]))
fwrite(obs, "outputs/tables/camarao_leakage_decomposition.csv")
flush(stdout())

# ---------- (2) meses-placebo: cada mês de jun–dez como se fosse o tratado ----------
cat("\n== Randomização sobre meses-placebo (jun–dez), spec ihs pré-2023 + cobertura + SST ==\n")
real <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell)
rb <- coef(real); cat(sprintf("real: fev = %+.4f | mai = %+.4f\n", rb[["status::new_closed:post"]], rb[["status::new_open:post"]]))
pl <- list()
for (mo in 6:12) {
  q <- copy(p); q[, pm := as.integer(month == mo)]
  f <- feols(ihs_pre ~ i(status, post, ref = "open_both") + pm:post + ihs_pres + sst | cell^month + year, data = q, cluster = ~cell)
  pl[[length(pl) + 1]] <- data.table(placebo_month = mo, beta = coef(f)[["pm:post"]], se = se(f)[["pm:post"]])
}
pl <- rbindlist(pl); print(pl[, .(placebo_month, beta = round(beta, 4), se = round(se, 4))])
cat(sprintf("placebos: média %+.4f, dp %.4f, |max| %.4f | fev real %+.4f (rank %d/8) | mai real %+.4f (rank %d/8)\n",
            mean(pl$beta), sd(pl$beta), max(abs(pl$beta)),
            rb[["status::new_closed:post"]], sum(pl$beta <= rb[["status::new_closed:post"]]) + 1,
            rb[["status::new_open:post"]], sum(pl$beta >= rb[["status::new_open:post"]]) + 1))
fwrite(pl, "outputs/tables/camarao_placebo_months.csv")
flush(stdout())

# ---------- (3) substituição por arte (C5) ----------
cat("\n== C5: efeito por arte (frota pré-2023, ihs, cobertura + SST) ==\n")
g <- fread("data/processed/panel_camarao_gear.csv")
top <- g[, .(h = sum(hours)), by = geartype][order(-h)][h > 100000, geartype]
base <- p[, .(cell_lon, cell_lat, year, month, cell, post, status, ihs_pres, sst)]
res <- list()
for (gt in top) {
  gg <- merge(base, g[geartype == gt, .(cell_lon, cell_lat, year, month, hours_prefleet)], by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
  gg[is.na(hours_prefleet), hours_prefleet := 0]; gg[, y := asinh(hours_prefleet)]
  f <- feols(y ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = gg, cluster = ~cell)
  ct <- coeftable(f)
  res[[gt]] <- data.table(geartype = gt, hours_total = round(g[geartype == gt, sum(hours)]),
                          fev = round(ct["status::new_closed:post", 1], 3), fev_p = round(ct["status::new_closed:post", 4], 3),
                          mai = round(ct["status::new_open:post", 1], 3), mai_p = round(ct["status::new_open:post", 4], 3),
                          marabr = round(ct["status::closed_both:post", 1], 3))
}
res <- rbindlist(res); print(res); fwrite(res, "outputs/tables/camarao_gear_substitution.csv")
