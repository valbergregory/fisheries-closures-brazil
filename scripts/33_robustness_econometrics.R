# Bateria adicional de robustez econométrica do caso camarão.
# (1) formas funcionais alternativas da variável dependente;
# (2) leave-one-state-out;
# (3) sensibilidade a violações de tendências paralelas (Rambachan & Roth,
#     implementação própria de "relative magnitudes" — HonestDiD não está
#     disponível no CRAN neste ambiente);
# (4) inferência espacial por bootstrap de blocos latitudinais;
# (5) estimadores heterogêneos: como o tratamento é simultâneo (2023) e
#     binário, Callaway-Sant'Anna/Sun-Abraham coincidem com o TWFE; o que
#     testamos é a heterogeneidade por célula via interação com o nível pré.
# Rodar: Rscript scripts/33_robustness_econometrics.R
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/24_camarao_prep.R")
p <- prep_camarao()
OUT <- "outputs/tables"
base_rhs <- "i(status, post, ref = 'open_both') + ihs_pres + sst | cell^month + year"

## ---------------------------------------------------------------- (1)
cat("== (1) Formas funcionais da dependente ==\n")
p[, `:=`(log1p_tr = log1p(trawl_hours_prefleet),
         lev_tr   = trawl_hours_prefleet,
         bin_tr   = as.integer(trawl_hours_prefleet > 0),
         share_tr = fifelse(presence_hours > 0, trawl_hours_prefleet / presence_hours, NA_real_))]
forms <- list(
  asinh   = ihs_pre   ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year,
  log1p   = log1p_tr  ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year,
  nivel   = lev_tr    ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year,
  extensiva = bin_tr  ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year,
  fracao  = share_tr  ~ i(status, post, ref = "open_both") + sst | cell^month + year)
r1 <- rbindlist(lapply(names(forms), function(k) {
  f <- feols(forms[[k]], data = p, cluster = ~cell); ct <- coeftable(f)
  data.table(forma = k, fev = round(ct["status::new_closed:post", 1], 3), fev_se = round(ct["status::new_closed:post", 2], 3),
             mai = round(ct["status::new_open:post", 1], 3), mai_se = round(ct["status::new_open:post", 2], 3))
}))
print(r1); fwrite(r1, file.path(OUT, "rob1_formas_funcionais.csv"))

## ---------------------------------------------------------------- (2)
cat("\n== (2) Leave-one-state-out ==\n")
r2 <- rbindlist(lapply(c("(todas)", sort(unique(p$uf))), function(u) {
  sub <- if (u == "(todas)") p else p[uf != u]
  f <- feols(forms$asinh, data = sub, cluster = ~cell); ct <- coeftable(f)
  data.table(excluida = u, celulas = uniqueN(sub$cell),
             fev = round(ct["status::new_closed:post", 1], 3), fev_se = round(ct["status::new_closed:post", 2], 3),
             mai = round(ct["status::new_open:post", 1], 3), mai_se = round(ct["status::new_open:post", 2], 3))
}))
print(r2); fwrite(r2, file.path(OUT, "rob2_leave_one_state_out.csv"))

## ---------------------------------------------------------------- (3)
# Rambachan & Roth "relative magnitudes": qual M (razão entre a maior violação
# pós e a maior variação pré-tratamento) ainda mantém o efeito longe de zero?
cat("\n== (3) Sensibilidade a tendências não paralelas (relative magnitudes) ==\n")
rr <- list()
for (mo in c(2, 5)) {
  sub <- p[month %in% c(mo, 7:12)]; sub[, tm := as.integer(month == mo)]; sub[, rel := year - 2023L]
  f <- feols(ihs_pre ~ i(rel, tm, ref = -1) + ihs_pres + sst | cell^month + year, data = sub, cluster = ~cell)
  ct <- coeftable(f); nm <- grep("^rel::", rownames(ct), value = TRUE)
  rq <- as.integer(gsub(":tm", "", gsub("rel::", "", nm, fixed = TRUE), fixed = TRUE))
  pre <- ct[nm[rq < 0], 1]; post <- ct[nm[rq >= 0], 1]
  delta_pre <- max(abs(diff(c(pre, 0))))        # maior variação entre leads consecutivos
  effect <- mean(post)
  M_break <- abs(effect) / delta_pre            # M que zera o efeito
  rr[[length(rr) + 1]] <- data.table(mes = ifelse(mo == 2, "fevereiro", "maio"),
    efeito_medio_pos = round(effect, 3), maior_variacao_pre = round(delta_pre, 3),
    M_que_anula = round(M_break, 2))
}
r3 <- rbindlist(rr); print(r3)
cat("Interpretação: M = quantas vezes a maior variação pré-tratamento a violação\n",
    "pós-tratamento precisaria ser para anular o efeito. M > 1 = robusto.\n")
fwrite(r3, file.path(OUT, "rob3_honest_did_rm.csv"))

## ---------------------------------------------------------------- (4)
cat("\n== (4) Bootstrap de blocos latitudinais (dependência espacial) ==\n")
set.seed(20260903)
p[, lat_block := cut(cell_lat, breaks = seq(-34, -21, by = 1), labels = FALSE)]
blocks <- sort(unique(p$lat_block[!is.na(p$lat_block)]))
B <- 400L; bf <- bm <- numeric(B)
for (b in seq_len(B)) {
  sel <- sample(blocks, length(blocks), replace = TRUE)
  idx <- unlist(lapply(seq_along(sel), function(i) which(p$lat_block == sel[i])))
  d <- p[idx]; d[, cell := paste(cell, rep(seq_along(sel), times = sapply(sel, function(s) sum(p$lat_block == s, na.rm = TRUE))))]
  f <- tryCatch(feols(forms$asinh, data = d, notes = FALSE), error = function(e) NULL)
  if (!is.null(f)) { cf <- coef(f)
    bf[b] <- if ("status::new_closed:post" %in% names(cf)) cf[["status::new_closed:post"]] else NA
    bm[b] <- if ("status::new_open:post" %in% names(cf)) cf[["status::new_open:post"]] else NA }
}
bf <- bf[is.finite(bf) & bf != 0]; bm <- bm[is.finite(bm) & bm != 0]
r4 <- data.table(mes = c("fevereiro", "maio"),
                 media_boot = round(c(mean(bf), mean(bm)), 3), dp_boot = round(c(sd(bf), sd(bm)), 3),
                 ic_low = round(c(quantile(bf, .025), quantile(bm, .025)), 3),
                 ic_high = round(c(quantile(bf, .975), quantile(bm, .975)), 3), B = c(length(bf), length(bm)))
print(r4); fwrite(r4, file.path(OUT, "rob4_block_bootstrap.csv"))

## ---------------------------------------------------------------- (5)
cat("\n== (5) Heterogeneidade por intensidade pré-reforma da célula ==\n")
pre_int <- p[year <= 2022, .(pre_hours = sum(trawl_hours_prefleet)), by = cell]
pre_int[, tercil := cut(pre_hours, quantile(pre_hours, c(0, 1/3, 2/3, 1)), include.lowest = TRUE, labels = c("baixo", "médio", "alto"))]
p2 <- merge(p, pre_int[, .(cell, tercil)], by = "cell")
r5 <- rbindlist(lapply(levels(p2$tercil), function(tc) {
  f <- feols(forms$asinh, data = p2[tercil == tc], cluster = ~cell); ct <- coeftable(f)
  data.table(tercil_intensidade = tc, celulas = uniqueN(p2[tercil == tc, cell]),
             fev = round(ct["status::new_closed:post", 1], 3), mai = round(ct["status::new_open:post", 1], 3))
}))
print(r5); fwrite(r5, file.path(OUT, "rob5_terciles.csv"))
cat("\nArquivos em", OUT, "\n")
