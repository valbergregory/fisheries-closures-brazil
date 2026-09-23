# Inferência do caso camarão com poucos clusters (5 UFs): cluster por UF com
# t(G-1) e wild cluster bootstrap-t restrito com pesos de Webb (R/26).
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/24_camarao_prep.R"); source("R/26_inference.R")
p <- prep_camarao()
fml <- ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year

f_cell <- feols(fml, data = p, cluster = ~cell)
f_uf   <- feols(fml, data = p, cluster = ~uf)
cat("== Comparação de erros-padrão ==\n")
print(etable(f_cell, f_uf, headers = c("cluster célula (n=324)", "cluster UF (G=5)"), digits = 3))

cat("\n== Wild cluster bootstrap-t (Webb, B=999, cluster = UF) ==\n")
res <- list()
for (cf in c("status::new_closed:post", "status::new_open:post", "status::closed_both:post", "status::mixed_jan:post")) {
  b <- wild_cluster_boot(p, fml, cf, "uf", B = 999L)
  res[[cf]] <- data.table(coef_name = cf, estimate = round(b$coef, 4), se_uf = round(b$se_cluster, 4),
                          t = round(b$t_obs, 3), p_wcb = round(b$p_boot, 4),
                          ci_low = round(b$ci_boot[1], 3), ci_high = round(b$ci_boot[2], 3), G = b$G, B = b$B_used)
  cat(sprintf("%-28s beta %+.4f | t %+.2f | p_WCB %.4f | IC95 [%+.3f, %+.3f]\n",
              sub("status::", "", cf), b$coef, b$t_obs, b$p_boot, b$ci_boot[1], b$ci_boot[2]))
}
tab <- rbindlist(res); fwrite(tab, "outputs/tables/camarao_wild_bootstrap.csv")
