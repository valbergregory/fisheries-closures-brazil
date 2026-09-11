# Background Job — D14, passo 1: quem pesca na APA depois da designação?
# Decompõe as horas de pesca na APA no pós-período (2018-03..2020-12) por
# origem da embarcação: incumbente (já pescava na APA), realocada (pescava
# no bbox fora da APA) ou nova na região (sem esforço no bbox antes).
suppressPackageStartupMessages({ library(data.table) })
v <- fread("data/processed/vessel_zone_month_trindade.csv")
v[, post := as.integer(year > 2018 | (year == 2018 & month >= 3))]
v[, ring := grepl("^ring", zone)]
per <- v[, .(apa_pre = sum(fishing_hours[zone == "apa" & post == 0]),
             apa_pos = sum(fishing_hours[zone == "apa" & post == 1]),
             mona_pre = sum(fishing_hours[zone == "mona" & post == 0]),
             mona_pos = sum(fishing_hours[zone == "mona" & post == 1]),
             ring_pre = sum(fishing_hours[ring & post == 0]),
             ring_pos = sum(fishing_hours[ring & post == 1]),
             ctrl_pre = sum(fishing_hours[zone == "control" & post == 0]),
             ctrl_pos = sum(fishing_hours[zone == "control" & post == 1]),
             all_pre = sum(fishing_hours[post == 0]), all_pos = sum(fishing_hours[post == 1]),
             flag = flag[1], geartype = geartype[1]), by = vessel_id]
per[, origin := fcase(apa_pre > 0, "incumbente_APA",
                      apa_pre == 0 & all_pre > 0, "realocada_da_regiao",
                      all_pre == 0, "nova_na_regiao")]
cat("== Embarcações com esforço na APA no pós-período, por origem ==\n")
dec <- per[apa_pos > 0, .(n_vessels = .N, apa_hours_pos = round(sum(apa_pos)),
                          share_apa_hours = round(100 * sum(apa_pos) / sum(per[apa_pos > 0, apa_pos]), 1),
                          apa_hours_pre = round(sum(apa_pre))), by = origin][order(-apa_hours_pos)]
print(dec); fwrite(dec, "outputs/tables/apa_decomposition_by_origin.csv")

cat("\n== Frota da APA por bandeira e arte (horas pós, top 12) ==\n")
print(per[apa_pos > 0, .(hours = round(sum(apa_pos)), n = .N), by = .(flag, geartype)][order(-hours)][1:12])

cat("\n== Realocadas: de onde vinham (distribuição das horas PRÉ por zona) ==\n")
rel <- per[origin == "realocada_da_regiao" & apa_pos > 0]
print(rel[, .(ring_pre = round(sum(ring_pre)), ctrl_pre = round(sum(ctrl_pre)), mona_pre = round(sum(mona_pre)),
              apa_pos = round(sum(apa_pos)), n = .N)])

cat("\n== DiD no nível da embarcação: fração das horas na APA, pré vs pós (embarcações ativas nos dois) ==\n")
both <- per[all_pre > 0 & all_pos > 0]
both[, `:=`(sh_pre = apa_pre / all_pre, sh_pos = apa_pos / all_pos)]
both[, d_share := sh_pos - sh_pre]
cat(sprintf("n = %d | fração média pré = %.3f | pós = %.3f | Δ = %+.3f (t = %.2f)\n",
            nrow(both), mean(both$sh_pre), mean(both$sh_pos), mean(both$d_share),
            mean(both$d_share) / (sd(both$d_share) / sqrt(nrow(both)))))
cat("Δ ponderado por horas totais:", round(with(both, sum(apa_pos) / sum(all_pos) - sum(apa_pre) / sum(all_pre)), 3), "\n")
print(both[, .(n = .N, d_share_mean = round(mean(d_share), 3), d_share_wtd = round(sum(apa_pos)/sum(all_pos) - sum(apa_pre)/sum(all_pre), 3)),
           by = geartype][order(-n)][1:6])

cat("\n== Anel 0-10 km: para onde foi o esforço das embarcações que pescavam lá antes? ==\n")
rr <- per[ring_pre > 0]
print(rr[, .(n = .N, ring_pre = round(sum(ring_pre)), ring_pos = round(sum(ring_pos)),
             apa_pos = round(sum(apa_pos)), ctrl_pos = round(sum(ctrl_pos)), all_pos = round(sum(all_pos)))])
fwrite(per, "data/processed/vessel_origin_trindade.csv")
