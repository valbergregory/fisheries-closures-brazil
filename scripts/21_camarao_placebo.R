# Background Job — placebo temporal do caso camarão: reforma fictícia em 2021
# (amostra 2018–2022, antes da reforma real). Esperado: coeficientes ~0.
suppressPackageStartupMessages({ library(data.table); library(fixest) })
source("R/24_camarao_prep.R")
p <- prep_camarao()[year <= 2022]
p[, post := as.integer(year >= 2021)]  # reforma FICTÍCIA em 2021
f <- feols(ihs_pre ~ i(status, post, ref = "open_both") + ihs_pres + sst | cell^month + year, data = p, cluster = ~cell)
cat("PLACEBO TEMPORAL — reforma fictícia em 2021 (2018-2022):\n"); ct <- coeftable(f); rows <- grep("status::", rownames(ct), value = TRUE)
print(round(ct[rows, , drop = FALSE], 4))
fwrite(as.data.table(ct[rows, , drop = FALSE], keep.rownames = TRUE), "outputs/tables/camarao_placebo_temporal.csv")
