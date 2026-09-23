# Heterogeneidade por UF e substituição de arte NO NÍVEL DA EMBARCAÇÃO (C5).
# Rodar: Rscript scripts/29_camarao_heterogeneity.R
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/24_camarao_prep.R")
p <- prep_camarao()

cat("== Efeito por UF (ihs, frota pré-2023, cobertura + SST) ==\n")
res <- list()
for (u in c("SC", "SP", "RS", "PR", "RJ")) {
  sub <- p[uf == u]
  if (uniqueN(sub$cell) < 8) { cat(u, ": poucas células\n"); next }
  f <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = sub, cluster = ~cell)
  ct <- coeftable(f)
  res[[u]] <- data.table(uf = u, celulas = uniqueN(sub$cell), horas = round(sub[, sum(trawl_hours)]),
    fev = round(ct["status::new_closed:post", 1], 3), fev_se = round(ct["status::new_closed:post", 2], 3),
    mai = round(ct["status::new_open:post", 1], 3), mai_se = round(ct["status::new_open:post", 2], 3))
}
tab <- rbindlist(res); print(tab); fwrite(tab, "outputs/tables/camarao_by_uf.csv")

# ---- C5 no nível da embarcação: a MESMA embarcação troca de arte? ----
cat("\n== C5: composição de artes por embarcação (fev e mai, antes vs depois) ==\n")
g <- fread("data/processed/panel_camarao_gear.csv")
g <- merge(g, unique(p[, .(cell_lon, cell_lat)]), by = c("cell_lon", "cell_lat"))
g[, post := as.integer(year >= 2023)]
g[, window := fcase(month == 2, "fev", month == 5, "mai", month %in% 3:4, "mar_abr", default = "outros")]
comp <- g[window %in% c("fev", "mai"), .(h = sum(hours_prefleet)), by = .(window, post, geartype)]
comp[, share := round(100 * h / sum(h), 1), by = .(window, post)]
w <- dcast(comp[share >= 1], geartype + window ~ post, value.var = "share", fill = 0)
setnames(w, c("0", "1"), c("pre_2023", "pos_2023")); w[, diff := round(pos_2023 - pre_2023, 1)]
print(w[order(window, -pos_2023)])
fwrite(w, "outputs/tables/camarao_gear_composition.csv")

# embarcações que pescavam com arrasto no pré e o que fizeram no pós, em fevereiro
v <- fread("data/processed/vessel_zone_month_trindade.csv")  # estrutura de referência
cat("\n(painel por embarcação do camarão não inclui vesselId — ver limitação em docs)\n")
cat("\n== Razão arrasto/outras artes nas janelas (frota pré-2023) ==\n")
r <- g[, .(trawl = sum(hours_prefleet[geartype == "TRAWLERS"]),
           other = sum(hours_prefleet[geartype != "TRAWLERS"])), by = .(window, post)]
r[, ratio := round(trawl / other, 2)]
print(dcast(r[window != "outros"], window ~ post, value.var = "ratio"))
