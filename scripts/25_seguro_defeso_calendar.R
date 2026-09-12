# C6 (descritivo): distribuição mensal dos beneficiários do Seguro-Defeso nos
# estados RJ–RS, por ano — a competência dos pagamentos acompanha o novo
# calendário (28/jan–30/abr) a partir de 2023? Agregado municipal (D9).
suppressPackageStartupMessages({ library(data.table) })
s <- fread("data/processed/seguro_defeso_municipio_mes.csv")
s[, `:=`(year = as.integer(substr(as.character(mes_referencia), 1, 4)), month = as.integer(substr(as.character(mes_referencia), 5, 6)))]
ses <- s[uf %in% c("RJ", "SP", "PR", "SC", "RS")]
tab <- ses[, .(benef = sum(n_beneficiarios), valor_mi = round(sum(valor_total) / 1e6, 1)), by = .(year, month)]
w <- dcast(tab, month ~ year, value.var = "benef"); cat("Beneficiários-mês (RJ+SP+PR+SC+RS) por mês de competência:\n"); print(w)
sh <- tab[, .(month, share = round(100 * benef / sum(benef), 1)), by = year]
ws <- dcast(sh, month ~ year, value.var = "share"); cat("\nParticipação (%) de cada mês no total anual:\n"); print(ws)
pre <- sh[year <= 2022, .(share_pre = mean(share)), by = month]; pos <- sh[year >= 2023, .(share_pos = mean(share)), by = month]
d <- merge(pre, pos, by = "month")[, diff := round(share_pos - share_pre, 1)]
cat("\nMudança da participação mensal (média 2023–24 menos média 2019–22), p.p.:\n"); print(d)
cat(sprintf("\nJan–Fev: %+.1f p.p. | Mar–Abr: %+.1f p.p. | Mai–Jun: %+.1f p.p.\n", d[month %in% 1:2, sum(diff)], d[month %in% 3:4, sum(diff)], d[month %in% 5:6, sum(diff)]))
fwrite(tab, "outputs/tables/seguro_defeso_ses_month_year.csv"); fwrite(d, "outputs/tables/seguro_defeso_calendar_shift.csv")
# por UF: onde a mudança é maior?
uf <- ses[, .(benef = sum(n_beneficiarios)), by = .(uf, year, month)][, share := 100 * benef / sum(benef), by = .(uf, year)]
ufd <- uf[, .(share = mean(share)), by = .(uf, month, post = year >= 2023)]
ufd <- dcast(ufd, uf + month ~ post, value.var = "share"); setnames(ufd, c("uf", "month", "pre", "pos")); ufd[, diff := round(pos - pre, 1)]
cat("\nPor UF — janeiro+fevereiro (p.p.):\n"); print(ufd[month %in% 1:2, .(jan_fev = sum(diff)), by = uf])
cat("Por UF — maio+junho (p.p.):\n"); print(ufd[month %in% 5:6, .(mai_jun = sum(diff)), by = uf])
