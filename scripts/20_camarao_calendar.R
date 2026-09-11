# Background Job — B3: desenho de calendário do defeso do camarão SE/S.
# Regime até 2022: defeso 1º/mar–31/mai (IN 189/2008; 2022 idem por transição).
# Regime desde 2023: 28/jan–30/abr (Portaria SAP/MAPA 656/2022).
# Status por mês: fev = LIVRE->PROIBIDO (C1); mai = PROIBIDO->LIVRE (C2);
# mar–abr = proibido nos dois; jan = misto (28–31 proibido só no pós);
# jun–dez = livre nos dois (referência/placebo).
# Inferência: cluster por célula e cluster duplo (célula, ano-mês). Conley
# com 126k linhas provoca segfault neste ambiente — não usar aqui.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
p <- fread("data/processed/panel_camarao.csv")
sst <- fread("data/interim/sst_camarao_monthly.csv")
p <- merge(p, sst[, .(cell_lon, cell_lat, year, month, sst)], by = c("cell_lon", "cell_lat", "year", "month"), all.x = TRUE)
p[, `:=`(cell = paste(cell_lon, cell_lat), post = as.integer(year >= 2023), ym = year * 100L + month,
         ihs_all = asinh(trawl_hours), ihs_pre = asinh(trawl_hours_prefleet),
         ihs_pres = asinh(presence_hours), ihs_other = asinh(other_hours))]
p[, status := fcase(month == 2, "new_closed", month == 5, "new_open", month %in% 3:4, "closed_both",
                    month == 1, "mixed_jan", default = "open_both")]
p[, status := factor(status, levels = c("open_both", "new_closed", "new_open", "closed_both", "mixed_jan"))]
cat("painel:", nrow(p), "| células:", uniqueN(p$cell), "| anos:", paste(range(p$year), collapse = "-"), "\n")
print(p[, .(trawl_all = round(sum(trawl_hours)), trawl_prefleet = round(sum(trawl_hours_prefleet)),
            presence = round(sum(presence_hours))), by = year][order(year)])
flush(stdout())

mA <- feols(ihs_all ~ i(status, post, ref = "open_both") | cell^month + year, data = p, cluster = ~cell)
mB <- feols(ihs_all ~ i(status, post, ref = "open_both") + ihs_pres | cell^month + year, data = p, cluster = ~cell)
mC <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres | cell^month + year, data = p, cluster = ~cell)
mD <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell)
mE <- fepois(trawl_hours_prefleet ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell)
mF <- feols(ihs_other ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell)
mG <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell + ym)
hdr <- c("A toda frota", "B +cobertura", "C pré-2023", "D +SST", "E PPML pré-2023", "F outras artes", "G cluster duplo")
print(etable(mA, mB, mC, mD, mE, mF, mG, headers = hdr, digits = 3))
etable(mA, mB, mC, mD, mE, mF, mG, file = "outputs/tables/camarao_calendar_main.tex", replace = TRUE, headers = hdr)
saveRDS(list(A = mA, B = mB, C = mC, D = mD, E = mE, F = mF, G = mG), "outputs/models/camarao_calendar.rds")
flush(stdout())

cat("\n== Event study anual (ref 2022): mês-alvo vs jul–dez, frota pré-2023, cobertura + SST ==\n")
es <- list()
for (mo in c(1, 2, 5, 3)) {
  sub <- p[month %in% c(mo, 7:12)]; sub[, tm := as.integer(month == mo)]; sub[, rel := year - 2023L]
  f <- feols(ihs_pre ~ i(rel, tm, ref = -1) + ihs_pres + sst | cell^month + year, data = sub, cluster = ~cell)
  ct <- coeftable(f); es[[as.character(mo)]] <- f
  cat(sprintf("\nmês %d:\n", mo)); print(round(ct[grep("rel", rownames(ct)), c(1, 2, 4)], 3))
}
saveRDS(es, "outputs/models/camarao_eventstudy.rds")
png("outputs/figures/camarao_eventstudy.png", width = 1800, height = 500, res = 130)
par(mfrow = c(1, 4), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
lab <- c("1" = "janeiro (misto: 28–31 fechado no pós)", "2" = "fevereiro (LIVRE -> PROIBIDO)", "5" = "maio (PROIBIDO -> LIVRE)", "3" = "março (proibido nos dois)")
for (k in names(es)) iplot(es[[k]], main = lab[k], xlab = "ano relativo (0 = 2023)", ylab = "ihs horas de arrasto")
mtext("Reforma do calendário do defeso do camarão SE/S (Portaria 656/2022) — frota com AIS pré-2023; ref = 2022", outer = TRUE, cex = 0.9)
dev.off()
