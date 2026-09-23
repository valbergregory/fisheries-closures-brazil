# Desenho de TRIPLAS DIFERENÇAS com a costa inteira.
# SE/S teve o calendário do defeso do camarão alterado em 2023; Norte
# (Port. MDIC/MMA 75/2017) e Nordeste (IN MMA 14/2004) NÃO tiveram.
# Pergunta: a queda de fevereiro e o salto de maio no SE/S são específicos
# da reforma, ou seguem uma tendência nacional do arrasto nesses meses?
# Rodar: Rscript scripts/35_triple_difference.R
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/24_camarao_prep.R")

ses <- prep_camarao()[, .(region = "SES", cell_lon, cell_lat, year, month, cell, post, status,
                          trawl_hours, trawl_hours_prefleet, presence_hours, coast_km, uf)]
out <- fread("data/processed/panel_costa.csv")
out[, `:=`(cell = paste(region, cell_lon, cell_lat), post = as.integer(year >= 2023))]
out[, status := fcase(month == 2, "new_closed", month == 5, "new_open", month %in% 3:4, "closed_both",
                      month == 1, "mixed_jan", default = "open_both")]
p <- rbind(ses, out[, .(region, cell_lon, cell_lat, year, month, cell, post, status,
                        trawl_hours, trawl_hours_prefleet, presence_hours, coast_km, uf)])
p[, status := factor(status, levels = c("open_both", "new_closed", "new_open", "closed_both", "mixed_jan"))]
p[, region := factor(region, levels = c("N", "NE", "SES"))]
p[, treated := as.integer(region == "SES")]
p[, `:=`(ihs_pre = asinh(trawl_hours_prefleet), ihs_all = asinh(trawl_hours), ihs_pres = asinh(presence_hours))]

cat("== Painel nacional ==\n")
print(p[, .(celulas = uniqueN(cell), horas_arrasto = round(sum(trawl_hours)),
            horas_prefrota = round(sum(trawl_hours_prefleet))), by = region])
flush(stdout())

cat("\n== (a) Efeito por região, separadamente (DiD dentro de cada região) ==\n")
res <- list()
for (rg in levels(p$region)) {
  sub <- p[region == rg]
  if (uniqueN(sub$cell) < 20) { cat(rg, ": poucas células\n"); next }
  f <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres | cell^month + year, data = sub, cluster = ~cell)
  ct <- coeftable(f)
  res[[rg]] <- data.table(regiao = rg, celulas = uniqueN(sub$cell),
    fev = round(ct["status::new_closed:post", 1], 3), fev_se = round(ct["status::new_closed:post", 2], 3),
    mai = round(ct["status::new_open:post", 1], 3), mai_se = round(ct["status::new_open:post", 2], 3))
}
tab <- rbindlist(res); print(tab); fwrite(tab, "outputs/tables/ddd_por_regiao.csv")

cat("\n== (b) Triplas diferenças: (mês tratado x pós x SE/S) ==\n")
m1 <- feols(ihs_pre ~ i(status, post, ref = "open_both") + i(status, treated, ref = "open_both") +
              I(treated*post) + i(status, I(treated*post), ref = "open_both") + ihs_pres | cell^month + year,
            data = p, cluster = ~cell)
ct1 <- coeftable(m1)
sel <- grep("treated", rownames(ct1), value = TRUE)
print(round(ct1[sel, , drop = FALSE], 4))
m2 <- feols(ihs_pre ~ i(status, I(treated*post), ref = "open_both") + i(status, post, ref = "open_both") +
              ihs_pres | cell^month + year + region^year, data = p, cluster = ~cell)
cat("\ncom efeitos fixos região x ano (absorve choques regionais anuais):\n")
ct2 <- coeftable(m2); print(round(ct2[grep("treated", rownames(ct2)), , drop = FALSE], 4))
saveRDS(list(ddd = m1, ddd_regyear = m2), "outputs/models/ddd_costa.rds")
etable(m1, m2, file = "outputs/tables/ddd_costa.tex", replace = TRUE,
       headers = c("DDD", "DDD + EF região-ano"), digits = 3)

cat("\n== (c) Placebo: o Norte/Nordeste 'reagiu' à reforma do SE/S? ==\n")
for (rg in c("N", "NE")) {
  sub <- p[region == rg]
  if (uniqueN(sub$cell) < 20) next
  f <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres | cell^month + year, data = sub, cluster = ~cell)
  ct <- coeftable(f)
  cat(sprintf("%-3s fev %+.3f (%.3f, p=%.3f) | mai %+.3f (%.3f, p=%.3f)\n", rg,
              ct["status::new_closed:post", 1], ct["status::new_closed:post", 2], ct["status::new_closed:post", 4],
              ct["status::new_open:post", 1], ct["status::new_open:post", 2], ct["status::new_open:post", 4]))
}
